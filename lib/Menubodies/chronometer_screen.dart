import 'dart:async';

import 'package:dusbuddy2/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için

class ChronometerScreen extends StatefulWidget {
  const ChronometerScreen({Key? key}) : super(key: key);

  @override
  State<ChronometerScreen> createState() => _ChronometerScreenState();
}

class _ChronometerScreenState extends State<ChronometerScreen> {
  late ChronometerDatabase db;
  Stopwatch _stopwatch = Stopwatch();
  Duration _duration = Duration();
  late String _formattedTime;
  TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _chronometerList = []; // Kayıtları saklamak için
  late Timer _timer; // Zamanlayıcı ekledik

  @override
  void initState() {
    super.initState();
    db = ChronometerDatabase();
    db.openDb();
    _formattedTime = _formatTime(_duration);
  }

  // Zamanı formatlama
  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // Kronometreyi başlatma
  void _startStopwatch() {
    setState(() {
      _stopwatch.start();
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _duration = _stopwatch.elapsed;
          _formattedTime = _formatTime(_duration);
        });
      });
    });
  }

  // Kronometreyi durdurma
  void _stopStopwatch() {
    setState(() {
      _stopwatch.stop();
      _timer.cancel(); // Zamanlayıcıyı durdur
    });
  }

  // Kronometreyi sıfırlama
  void _resetStopwatch() {
    setState(() {
      _stopwatch.reset();
      _duration = Duration();
      _formattedTime = _formatTime(_duration);
      _nameController.clear(); // Adı temizle
    });
  }

  // Süreyi veritabanına kaydetme
  void _saveChronometer() {
    String name = _nameController.text;
    String date = DateFormat('yyyy-MM-dd – kk:mm').format(DateTime.now());

    db.insertChronometer(name, _duration.inSeconds, date);
    _chronometerList.add({'name': name, 'duration': _duration.inSeconds, 'date': date}); // Listeye ekle

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Kronometre kaydedildi!")),
    );

    setState(() {}); // Listeyi güncelle
  }

  @override
  void dispose() {
    _timer.cancel(); // Timer'ı temizle
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kronometre')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Süre: $_formattedTime',
              style: TextStyle(fontSize: 48.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Kronometre Adı',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _startStopwatch,
                  child: Text('Başlat'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _stopStopwatch,
                  child: Text('Durdur'),
                ),
                SizedBox(width: 20),
                ElevatedButton(
                  onPressed: _resetStopwatch,
                  child: Text('Sıfırla'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveChronometer,
              child: Text('Kaydet'),
            ),
            SizedBox(height: 20),
            // Kayıtları gösteren liste
            Expanded(
              child: ListView.builder(
                itemCount: _chronometerList.length,
                itemBuilder: (context, index) {
                  final chronometer = _chronometerList[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(chronometer['name']),
                      subtitle: Text('Süre: ${_formatTime(Duration(seconds: chronometer['duration']))} - ${chronometer['date']}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
