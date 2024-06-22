import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:rw_git/rw_git.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProjectManager(),
      child: MaterialApp(
        title: 'ROS Project Generator for FRC',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomePage(),
        routes: {
          '/node': (context) => const NodePage(),
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _projectController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final projectManager = Provider.of<ProjectManager>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('ROS Project Generator for FRC Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Enter your project name:',
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _projectController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Project Name',
                ),
                onChanged: (value) {
                  projectManager.setProjectName(value);
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/node');
              },
              child: const Text('Add Nodes'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _selectFolderAndCloneRepo(context),
              child: const Text('Select Folder and Clone Repo'),
            ),
            if (projectManager.statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  projectManager.statusMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFolderAndCloneRepo(BuildContext context) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) {
      return; // User canceled the picker
    }
    if (!context.mounted) {
      return; // Prevents the error: Looking up a deactivated widget's ancestor is unsafe
    }
    final projectManager = Provider.of<ProjectManager>(context, listen: false);
    projectManager.cloneRepoAndCreateFolder(selectedDirectory);
  }
}

class NodePage extends StatefulWidget {
  const NodePage({super.key});

  @override
  State<NodePage> createState() => _NodePageState();
}

class _NodePageState extends State<NodePage> {
  final TextEditingController _nodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final projectManager = Provider.of<ProjectManager>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Add Nodes'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Enter the name of the node to be created:(all lowercase, no spaces, use underscores)',
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _nodeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Node Name',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nodeController.text.isNotEmpty) {
                  projectManager.addNode(_nodeController.text);
                  _nodeController.clear();
                }
              },
              child: const Text('Add Node'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nodes to be created:',
            ),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: ListView.builder(
                itemCount: projectManager.nodes.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(projectManager.nodes[index]),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class ProjectManager extends ChangeNotifier {
  String statusMessage = '';
  List<String> nodes = [];
  String projectName = '';

  void addNode(String node) {
    nodes.add(node);
    notifyListeners();
  }

  void setProjectName(String name) {
    projectName = name;
    notifyListeners();
  }

  Future<void> cloneRepoAndCreateFolder(String selectedDirectory) async {
    const repoUrl =
        'http://gitlab.team195.com/cyberknights/ros2/support-files/ros2_dev.git'; // Replace with the actual repo URL
    final gitDirectory = Directory(selectedDirectory);

    try {
      statusMessage = 'Cloning repository...';
      notifyListeners();

      // Clone the repository
      RwGit git = RwGit();
      await git.clone(gitDirectory.path, repoUrl);

      statusMessage = 'Repository cloned successfully.';
      notifyListeners();

      // Create a new folder alongside the cloned repo
      final newFolder = Directory('$selectedDirectory/$projectName');
      await newFolder.create();

      statusMessage =
          'New folder created successfully alongside the cloned repo.';
      notifyListeners();

      // Create the nodes in the new folder
      for (var node in nodes) {
        final nodeFolder = Directory('${newFolder.path}/$node');
        await nodeFolder.create();
      }

      statusMessage = 'Nodes created successfully.';
      notifyListeners();
    } catch (e) {
      statusMessage = 'Failed to clone repository: $e';
      notifyListeners();
    }
  }
}
