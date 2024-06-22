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
        home:
            const MyHomePage(title: 'ROS Project Generator for FRC Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _nodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final projectManager = Provider.of<ProjectManager>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
            if (projectManager.statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  projectManager.statusMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: () => _selectFolderAndCloneRepo(context),
              child: const Text('Select Folder and Clone Repo'),
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
    if (!mounted) {
      return; // Prevents the error: Looking up a deactivated widget's ancestor is unsafe
    }
    final projectManager = Provider.of<ProjectManager>(context, listen: false);
    projectManager.cloneRepoAndCreateFolder(selectedDirectory);
  }
}

class ProjectManager extends ChangeNotifier {
  String statusMessage = '';
  List<String> nodes = [];

  void addNode(String node) {
    nodes.add(node);
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
      final newFolder = Directory('$selectedDirectory/new_folder');
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
