import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  _MoodTrackerScreenState createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  Map<DateTime, String> moodByDate = {};
  bool isLoading = true;
  List<FlSpot> moodTrendSpots = [];
  String moodInsight = "No data available";

  // Calendar selection
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  // Get the current user.
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  Future<void> _loadMoodData() async {
    try {
      DateTime now = DateTime.now().toUtc();
      DateTime startDate = now.subtract(const Duration(days: 30));
      final entries = await _supabaseService.fetchEntries(
        userId: currentUser?.id,
        page: 1,
        limit: 100,
        startDate: startDate,
        endDate: now,
      );
      Map<DateTime, List<String>> moodsPerDay = {};
      for (var entry in entries) {
        DateTime dt = DateTime.parse(entry['created_at']).toLocal();
        DateTime day = DateTime(dt.year, dt.month, dt.day);
        moodsPerDay.putIfAbsent(day, () => []);
        moodsPerDay[day]!.add(entry['mood'] ?? 'No mood');
      }
      Map<DateTime, String> dominantMoodPerDay = {};
      moodsPerDay.forEach((day, moods) {
        Map<String, int> count = {};
        for (var mood in moods) {
          count[mood] = (count[mood] ?? 0) + 1;
        }
        String dominant = count.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
        dominantMoodPerDay[day] = dominant;
      });

      Map<String, double> moodValues = {
        "😊": 2,
        "😐": 1,
        "😔": 0,
        "No mood": -1,
      };

      List<FlSpot> spots = [];
      dominantMoodPerDay.forEach((day, mood) {
        double x = day.difference(startDate.toLocal()).inDays.toDouble();
        double y = moodValues[mood] ?? -1;
        spots.add(FlSpot(x, y));
      });
      spots.sort((a, b) => a.x.compareTo(b.x));

      Map<String, int> overallCounts = {};
      dominantMoodPerDay.forEach((day, mood) {
        overallCounts[mood] = (overallCounts[mood] ?? 0) + 1;
      });
      String overallDominant = overallCounts.isNotEmpty
          ? overallCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key
          : "No data";

      setState(() {
        moodByDate = dominantMoodPerDay;
        moodTrendSpots = spots;
        moodInsight = "Your most frequent mood in the last 30 days is $overallDominant.";
        isLoading = false;
      });
    } catch (e) {
      print("Error loading mood data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadMoodData();
  }

  Widget _buildCalendar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TableCalendar(
      firstDay: DateTime.now().subtract(const Duration(days: 60)),
      lastDay: DateTime.now().add(const Duration(days: 60)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
      },
      calendarStyle: CalendarStyle(
        markerDecoration: BoxDecoration(
          color: isDark ? Colors.deepOrange : primaryColor,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: isDark ? Colors.deepOrange.withOpacity(0.5) : primaryColor.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: isDark ? Colors.deepOrange : primaryColor,
          shape: BoxShape.circle,
        ),
        defaultTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black),
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        decoration: BoxDecoration(color: isDark ? Colors.black87 : primaryColor),
        titleCentered: true,
        leftChevronIcon: Icon(Icons.chevron_left, color: isDark ? Colors.white : Colors.black),
        rightChevronIcon: Icon(Icons.chevron_right, color: isDark ? Colors.white : Colors.black),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (moodByDate.containsKey(day)) {
            return Positioned(
              bottom: 1,
              child: Text(
                moodByDate[day]!,
                style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black),
              ),
            );
          }
          return Container();
        },
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        minY: -1,
        maxY: 3,
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                DateTime startDate = DateTime.now().toUtc().subtract(const Duration(days: 30)).toLocal();
                DateTime labelDate = startDate.add(Duration(days: value.toInt()));
                return Text("${labelDate.month}/${labelDate.day}", style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: moodTrendSpots,
            isCurved: true,
            barWidth: 3,
            dotData: FlDotData(show: true),
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.5)],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar.
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: Theme.of(context).brightness == Brightness.dark
                ? [Colors.black, Colors.grey.shade800]
                : [Colors.white, Colors.teal.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Select a date to view your mood", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildCalendar(),
                      const Divider(height: 32, thickness: 2),
                      const Text("Mood Trend (Last 30 Days)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: _buildLineChart(),
                      ),
                      const Divider(height: 32, thickness: 2),
                      Text(
                        moodInsight,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      // Additional elements like detailed logs or insights can be added here.
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
