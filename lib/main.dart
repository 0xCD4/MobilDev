// main.dart
// Ahmet Göker - 1030510380
//
// PROJE RAPORU
// Erciyes Üniversitesi
// Mühendislik Fakültesi
// Bilgisayar Mühendisliği Bölümü
// 
// Mobile Application Development Dersi
// Dr. Öğr. Üyesi Fehim Köylü
// 
// Proje Adı: Flutter ile Local Storage Not Uygulaması
// Proje Ödevi
//
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUrlStrategy(PathUrlStrategy());
  runApp(const NotesApp());
}

class NotesApp extends StatelessWidget {
  const NotesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const NotesHomePage(),
    );
  }
}

class Note {
  String id;
  String title;
  String content;
  DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };
}

class NotesHomePage extends StatefulWidget {
  const NotesHomePage({Key? key}) : super(key: key);

  @override
  _NotesHomePageState createState() => _NotesHomePageState();
}

class _NotesHomePageState extends State<NotesHomePage> {
  List<Note> _notes = [];
  bool _isLoading = true;
  final String _storageKey = 'notes_data';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  // Load notes from localStorage
  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoading = true;
    });

    try {
      final String? notesJson = prefs.getString(_storageKey);
      if (notesJson != null) {
        final List<dynamic> decoded = jsonDecode(notesJson);
        final loadedNotes = decoded.map((item) => Note.fromJson(item)).toList();
        
        setState(() {
          _notes = loadedNotes;
        });
      }
    } catch (e) {
      // Handle any errors loading data
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading notes: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Save notes to localStorage
  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedNotes = jsonEncode(_notes.map((note) => note.toJson()).toList());
    await prefs.setString(_storageKey, encodedNotes);
  }

  // Add a new note
  Future<void> _addNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(isNewNote: true),
      ),
    );

    if (result != null && result is Note) {
      setState(() {
        _notes.add(result);
      });
      await _saveNotes();
    }
  }

  // Edit existing note
  Future<void> _editNote(Note note) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(
          isNewNote: false,
          note: note,
        ),
      ),
    );

    if (result != null && result is Note) {
      setState(() {
        final index = _notes.indexWhere((n) => n.id == note.id);
        if (index != -1) {
          _notes[index] = result;
        }
      });
      await _saveNotes();
    }
  }

  // Delete a note
  Future<void> _deleteNote(Note note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _notes.removeWhere((n) => n.id == note.id);
      });
      await _saveNotes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortOptions();
            },
            tooltip: 'Sort notes',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? _buildEmptyState()
              : _buildNotesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        tooltip: 'Add Note',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.note_alt_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No notes yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create a note',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        final note = _notes[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(
              note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(note.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () => _editNote(note),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteNote(note),
            ),
          ),
        );
      },
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Sort by title'),
                onTap: () {
                  setState(() {
                    _notes.sort((a, b) => a.title.compareTo(b.title));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Sort by date (newest first)'),
                onTap: () {
                  setState(() {
                    _notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time_filled),
                title: const Text('Sort by date (oldest first)'),
                onTap: () {
                  setState(() {
                    _notes.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${_padZero(date.month)}-${_padZero(date.day)} ${_padZero(date.hour)}:${_padZero(date.minute)}';
  }

  String _padZero(int num) => num.toString().padLeft(2, '0');
}

// Note editor page
class NoteEditorPage extends StatefulWidget {
  final bool isNewNote;
  final Note? note;

  const NoteEditorPage({
    Key? key,
    required this.isNewNote,
    this.note,
  }) : super(key: key);

  @override
  _NoteEditorPageState createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');

    // Listen for changes to detect modifications
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isModified) {
      setState(() {
        _isModified = true;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    final Note savedNote = widget.isNewNote
        ? Note(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            content: content,
          )
        : Note(
            id: widget.note!.id,
            title: title,
            content: content,
            createdAt: widget.note!.createdAt,
          );

    Navigator.pop(context, savedNote);
  }

  Future<bool> _onWillPop() async {
    if (!_isModified) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DISCARD'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isNewNote ? 'New Note' : 'Edit Note'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNote,
              tooltip: 'Save',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                autofocus: widget.isNewNote,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}