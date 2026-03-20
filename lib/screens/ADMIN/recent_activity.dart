import 'package:flutter/material.dart';

class RecentActivityPage extends StatefulWidget {
  final List<dynamic> activities;
  final bool isLoading;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;

  const RecentActivityPage({
    super.key,
    required this.activities,
    required this.isLoading,
    required this.onBack,
    required this.onRefresh,
  });

  @override
  State<RecentActivityPage> createState() => _RecentActivityPageState();
}

class _RecentActivityPageState extends State<RecentActivityPage> {
  final Color primaryMaroon = const Color(0xFF4A152C);
  final Color bgLight = const Color(0xFFF8F9FA);
  
  // ✅ Search Controller and Filtered List
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredActivities = [];

  @override
  void initState() {
    super.initState();
    _filteredActivities = widget.activities;
    _searchController.addListener(_filterActivities);
  }

  // ✅ Filtering Logic
  void _filterActivities() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredActivities = widget.activities.where((act) {
        final title = (act['title'] ?? "").toString().toLowerCase();
        final type = (act['type'] ?? "").toString().toLowerCase();
        return title.contains(query) || type.contains(query);
      }).toList();
    });
  }

  @override
  void didUpdateWidget(RecentActivityPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activities != widget.activities) {
      _filterActivities(); // Update filtered list if master list changes
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgLight,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: widget.onBack,
                color: primaryMaroon,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Full Activity Log",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryMaroon),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.grey),
                onPressed: widget.onRefresh,
                tooltip: "Refresh Log",
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "Viewing all recent system updates and alumni interactions.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          
          const SizedBox(height: 24),

          // ✅ NEW: Search Bar UI
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by alumni name or activity type...",
                prefixIcon: Icon(Icons.search, color: primaryMaroon),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                suffixIcon: _searchController.text.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.clear), 
                      onPressed: () => _searchController.clear()
                    ) 
                  : null,
              ),
            ),
          ),

          const SizedBox(height: 24),
          
          // Activity List
          Expanded(
            child: RefreshIndicator(
              onRefresh: widget.onRefresh,
              color: primaryMaroon,
              child: widget.isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : _filteredActivities.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(child: Text(_searchController.text.isEmpty 
                          ? "No activity history found." 
                          : "No results matching \"${_searchController.text}\"")),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _filteredActivities.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final act = _filteredActivities[index];
                        
                        IconData icon = Icons.edit_note;
                        if (act['type'] == 'Tracer') {
                          icon = Icons.description_outlined;
                        } else if (act['type'] == 'Announcement') {
                          icon = Icons.campaign;
                        } else if (act['type'] == 'Verification') {
                          icon = Icons.verified_user;
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          leading: CircleAvatar(
                            backgroundColor: primaryMaroon.withValues(alpha: 0.1),
                            child: Icon(icon, color: primaryMaroon, size: 20),
                          ),
                          title: Text(
                            act['title'] ?? "Activity", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                          ),
                          subtitle: Text(
                            "${act['time']} • ${act['type']}",
                            style: const TextStyle(fontSize: 13)
                          ),
                          trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
                          onTap: () {},
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}