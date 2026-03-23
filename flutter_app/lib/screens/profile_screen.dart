import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../models/user_model.dart';
import 'mesh/mesh_radar_widget.dart';

class MockChatState {
  static final List<Map<String, String>> messages = [
    {'sender': 'doctor', 'text': 'Hello! How can I help you today?'},
    {'sender': 'patient', 'text': 'I have been experiencing a mild chest pain since yesterday.'},
    {'sender': 'doctor', 'text': 'I see. Is it a sharp pain or a dull ache? Does it radiate anywhere?'},
  ];
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060d14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a1520),
        title: const Text('Patient Profile & Settings', style: TextStyle(color: Color(0xFFc8dae8), fontFamily: 'monospace')),
        iconTheme: const IconThemeData(color: Color(0xFF00e5ff)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFF1a3040),
                child: Icon(Icons.person, size: 50, color: Color(0xFF00e5ff)),
              ),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'BASIC DETAILS',
              children: [
                _buildRow('Name', 'Jane Doe'),
                _buildRow('DOB', '15-Aug-1990 (Age: 35)'),
                _buildRow('Phone', '+1 (555) 019-2838'),
                _buildRow('Area', 'Downtown Sector 4'),
              ]
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'MEDICAL INFO',
              children: [
                _buildRow('Blood Group', 'O+'),
                _buildRow('Height', '168 cm'),
                _buildRow('Weight', '62 kg'),
                _buildRow('Known Allergies', 'Penicillin, Peanuts', isCrit: true),
              ]
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'EMERGENCY CONTACTS (NOTIFIED ON CRITICAL ALERT)',
              children: [
                _buildRow('John Doe (Husband)', '+1 (555) 111-2222'),
                _buildRow('Jane Smith (Sister)', '+1 (555) 333-4444'),
              ]
            ),
            const SizedBox(height: 16),
            _buildSection(
              title: 'ASSIGNED DOCTOR',
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(backgroundColor: Color(0xFF00e5ff), child: Icon(Icons.medical_services, color: Color(0xFF060d14))),
                  title: const Text('Dr. Sarah Jenkins', style: TextStyle(color: Color(0xFFc8dae8))),
                  subtitle: const Text('Cardiologist (General Hosp)\nActive Plan • Expires in 345 Days', style: TextStyle(color: Color(0xFF69ff47), fontSize: 12)),
                  isThreeLine: true,
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorListScreen()));
                    }, 
                    child: const Text('Change Doctor', style: TextStyle(color: Color(0xFF00e5ff)))
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorChatScreen(doctorName: 'Dr. Sarah Jenkins'))),
                    icon: const Icon(Icons.chat),
                    label: const Text('Direct Message & Calling Hub', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00e5ff), foregroundColor: const Color(0xFF060d14), padding: const EdgeInsets.symmetric(vertical: 16)),
                  ),
                ),
              ]
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _mockNav(BuildContext context, String title) {
    Navigator.push(context, MaterialPageRoute(builder: (ctx) => Scaffold(
      backgroundColor: const Color(0xFF060d14),
      appBar: AppBar(title: Text(title, style: const TextStyle(color: Color(0xFFc8dae8))), backgroundColor: const Color(0xFF0a1520), iconTheme: const IconThemeData(color: Color(0xFF00e5ff))),
      body: Center(child: Text('RBAC Protected Area: $title\n\nFull management tools load here.', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF4a6478), fontSize: 16))),
    )));
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0c1824),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1a3040)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF4a6478), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isCrit = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF4a6478), fontSize: 14)),
          Text(value, style: TextStyle(color: isCrit ? const Color(0xFFff5252) : const Color(0xFFc8dae8), fontSize: 14, fontWeight: isCrit ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});
  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  String _searchQuery = '';
  final List<Map<String, String>> _allDoctors = [
    {'name': 'Dr. Sarah Jenkins', 'specialty': 'Cardiologist', 'hosp': 'General Hosp', 'exp': '12', 'avail': 'Mon-Fri, 9AM-5PM', 'mPlan': 'FREE', 'yPlan': 'FREE'},
    {'name': 'Dr. Mark Sloan', 'specialty': 'Neurologist', 'hosp': 'City Med', 'exp': '18', 'avail': 'Tue-Thu, 10AM-4PM', 'mPlan': '\$69/mo', 'yPlan': '\$690/yr'},
    {'name': 'Dr. Emily Chen', 'specialty': 'Dermatologist', 'hosp': 'SkinCare Clinic', 'exp': '8', 'avail': 'Mon-Sat, 9AM-1PM', 'mPlan': '\$39/mo', 'yPlan': '\$390/yr'},
    {'name': 'Dr. James Wilson', 'specialty': 'Oncologist', 'hosp': 'General Hosp', 'exp': '20', 'avail': 'Mon-Wed, 8AM-2PM', 'mPlan': '\$89/mo', 'yPlan': '\$890/yr'},
    {'name': 'Dr. Gregory House', 'specialty': 'Infectious Disease', 'hosp': 'Princeton Med', 'exp': '25', 'avail': 'On Call', 'mPlan': '\$120/mo', 'yPlan': '\$1200/yr'},
    {'name': 'Dr. Lisa Cuddy', 'specialty': 'Endocrinologist', 'hosp': 'Princeton Med', 'exp': '15', 'avail': 'Mon-Fri, 9AM-5PM', 'mPlan': '\$79/mo', 'yPlan': '\$790/yr'},
    {'name': 'Dr. Derek Shepherd', 'specialty': 'Neurosurgeon', 'hosp': 'Seattle Grace', 'exp': '22', 'avail': 'Surgery Only', 'mPlan': '\$150/mo', 'yPlan': '\$1500/yr'},
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _allDoctors.where((d) => 
      d['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      d['specialty']!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF060d14),
      appBar: AppBar(title: const Text('Find a Doctor', style: TextStyle(color: Color(0xFFc8dae8))), backgroundColor: const Color(0xFF0a1520), iconTheme: const IconThemeData(color: Color(0xFF00e5ff))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Filter by name or specialty...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF00e5ff)),
                filled: true,
                fillColor: const Color(0xFF1a3040),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, i) {
                final d = filtered[i];
                return Card(
                  color: const Color(0xFF0c1824),
                  margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xFF1a3040))),
                  child: ExpansionTile(
                    leading: const CircleAvatar(backgroundColor: Color(0xFF00e5ff), child: Icon(Icons.person, color: Color(0xFF060d14))),
                    title: Text(d['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('${d['specialty']} • ${d['hosp']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    iconColor: const Color(0xFF00e5ff),
                    collapsedIconColor: Colors.white54,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFF1a3040).withOpacity(0.5)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Exp: ${d['exp']} Years', style: const TextStyle(color: Color(0xFFc8dae8), fontSize: 12)),
                                Text('Avail: ${d['avail']}', style: const TextStyle(color: Color(0xFFc8dae8), fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFF060d14), borderRadius: BorderRadius.circular(8)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: const [Icon(Icons.star, color: Color(0xFFffab00), size: 14), SizedBox(width: 8), Expanded(child: Text('24/7 Direct Telemedicine Chat Access', style: TextStyle(color: Color(0xFFc8dae8), fontSize: 11)))]),
                                  const SizedBox(height: 6),
                                  Row(children: const [Icon(Icons.bolt, color: Color(0xFFffab00), size: 14), SizedBox(width: 8), Expanded(child: Text('Automatic Alert Responses & Priority Care', style: TextStyle(color: Color(0xFFc8dae8), fontSize: 11)))]),
                                ]
                              )
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildPlanCard('Monthly Plan', d['mPlan']!, false)),
                                const SizedBox(width: 12),
                                Expanded(child: _buildPlanCard('Yearly Plan', d['yPlan']!, true)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (d['mPlan'] == 'FREE') {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assigned to ${d['name']} for free!'), backgroundColor: const Color(0xFF00e5ff), duration: const Duration(seconds: 2)));
                                  } else {
                                    _showPaymentModal(context, d);
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00e5ff), foregroundColor: const Color(0xFF060d14)),
                                child: Text(d['mPlan'] == 'FREE' ? 'Select Doctor' : 'Select & Subscribe', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPlanCard(String title, String price, bool isRecommended) {
    bool isFree = price == 'FREE';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecommended && !isFree ? const Color(0xFF00e5ff).withOpacity(0.1) : Colors.transparent,
        border: Border.all(color: isRecommended && !isFree ? const Color(0xFF00e5ff) : Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: isRecommended && !isFree ? const Color(0xFF00e5ff) : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(price, style: TextStyle(color: isFree ? const Color(0xFF69ff47) : Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          if (isRecommended && !isFree)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF00e5ff), borderRadius: BorderRadius.circular(4)), child: const Text('Save 16%', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold))),
            )
        ],
      ),
    );
  }

  void _showPaymentModal(BuildContext context, Map<String, String> doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0c1824),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Secure Checkout', style: TextStyle(color: Color(0xFFc8dae8), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            const SizedBox(height: 12),
            Text('Subscribe to ${doctor['name']} for ${doctor['yPlan']}', style: const TextStyle(color: Color(0xFF4a6478), fontSize: 14)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=upi://pay?pa=doctor@upi&pn=VitalSense&am=${doctor['yPlan']!.replaceAll(RegExp(r'[^0-9]'), '')}',
                height: 150, width: 150,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Scan with GPay / PhonePe / Razorpay', style: TextStyle(color: Color(0xFF00e5ff), fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close modal
                  Navigator.pop(context); // Close doctor list
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment Successful! Subscription Active.'), backgroundColor: Color(0xFF69ff47), duration: Duration(seconds: 3)));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF69ff47), foregroundColor: const Color(0xFF060d14), padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Simulate Payment Success', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      )
    );
  }
}

class DoctorChatScreen extends StatefulWidget {
  final String doctorName;
  final bool isTab;
  final bool isDoctorView;
  const DoctorChatScreen({super.key, required this.doctorName, this.isTab = false, this.isDoctorView = false});

  @override
  State<DoctorChatScreen> createState() => _DoctorChatScreenState();
}

class _DoctorChatScreenState extends State<DoctorChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();

  void _sendMsg() {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() {
      MockChatState.messages.add({
        'sender': widget.isDoctorView ? 'doctor' : 'patient',
        'text': _msgCtrl.text.trim()
      });
      _msgCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060d14),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isTab,
        title: Row(
          children: [
            const CircleAvatar(radius: 16, backgroundColor: Color(0xFF00e5ff), child: Icon(Icons.person, size: 20, color: Color(0xFF060d14))),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.doctorName, style: const TextStyle(color: Color(0xFFc8dae8), fontSize: 16))),
          ],
        ),
        backgroundColor: const Color(0xFF0a1520),
        iconTheme: const IconThemeData(color: Color(0xFF00e5ff)),
        actions: [
          IconButton(icon: const Icon(Icons.videocam), onPressed: () => _simulateCall(context, widget.doctorName, 'Video Call Request sent to ${widget.doctorName}')),
          IconButton(icon: const Icon(Icons.call), onPressed: () => _simulateCall(context, widget.doctorName, 'Voice Call Request sent to ${widget.doctorName}')),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: MockChatState.messages.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) return const Center(child: Text('Today', style: TextStyle(color: Colors.white38, fontSize: 12)));
                if (index == 1) return const SizedBox(height: 16);
                final msg = MockChatState.messages[index - 2];
                final isMe = widget.isDoctorView ? msg['sender'] == 'doctor' : msg['sender'] == 'patient';
                return _buildMessage(msg['text']!, isMe);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF0a1520),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.attach_file, color: Colors.white54), onPressed: (){}),
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      onSubmitted: (_) => _sendMsg(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color(0xFF1a3040),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF00e5ff),
                    child: IconButton(icon: const Icon(Icons.send, color: Color(0xFF060d14)), onPressed: _sendMsg),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF00e5ff) : const Color(0xFF1a3040),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Text(text, style: TextStyle(color: isMe ? const Color(0xFF060d14) : Colors.white)),
      ),
    );
  }

  void _simulateCall(BuildContext context, String name, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: const Color(0xFF00e5ff), duration: const Duration(seconds: 2)));
    
    // Simulate reverse notification 3 seconds later
    Future.delayed(const Duration(seconds: 3), () {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF0c1824),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF1a3040))),
            title: Column(
              children: [
                const CircleAvatar(radius: 30, backgroundColor: Color(0xFF00e5ff), child: Icon(Icons.person, size: 40, color: Color(0xFF060d14))),
                const SizedBox(height: 16),
                const Text('Incoming Call...', style: TextStyle(color: Colors.white54, fontSize: 14)),
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(backgroundColor: Colors.red, onPressed: () => Navigator.pop(ctx), child: const Icon(Icons.call_end, color: Colors.white)),
                FloatingActionButton(backgroundColor: Colors.green, onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Call Connected.'), backgroundColor: Color(0xFF69ff47)));
                }, child: const Icon(Icons.call, color: Colors.white)),
              ],
            )
          )
        );
      }
    });
  }
}
