import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'BloodTypeSelector.dart';

class HeightSelection extends StatefulWidget {
  const HeightSelection({Key? key}) : super(key: key);

  @override
  State<HeightSelection> createState() => _HeightSelectionState();
}

class _HeightSelectionState extends State<HeightSelection> {
  double selectedHeight = 170.0;
  final double minHeight = 120.0;
  final double maxHeight = 220.0;
  final double pixelsPerCm = 20.0;
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScrollPosition();
    });
  }

  void _initializeScrollPosition() {
    final initialScrollPosition = (maxHeight - selectedHeight) * pixelsPerCm;
    _scrollController.jumpTo(initialScrollPosition);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final newOffset = _scrollController.offset - details.delta.dy;
    final height = maxHeight - (newOffset / pixelsPerCm);
    
    if (height >= minHeight && height <= maxHeight) {
      setState(() {
        selectedHeight = height.roundToDouble();
        _scrollController.jumpTo(newOffset);
      });
    }
  }

  Future<void> _saveHeightToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('Medical data')
          .doc('height')
          .set({'height': selectedHeight, 'unit': 'cm'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF151515), Color(0xFF151515)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button and title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Assessment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '4 of 11',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Question text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Text(
                  "What's your height?",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Height selector
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // Scrollable height scale
                        GestureDetector(
                          onVerticalDragUpdate: _onVerticalDragUpdate,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const NeverScrollableScrollPhysics(),
                            child: SizedBox(
                              height: (maxHeight - minHeight) * pixelsPerCm,
                              child: CustomPaint(
                                size: Size(constraints.maxWidth, (maxHeight - minHeight) * pixelsPerCm),
                                painter: HeightScalePainter(
                                  minHeight: minHeight,
                                  maxHeight: maxHeight,
                                  scaleColor: Colors.white.withOpacity(0.3),
                                  pixelsPerCm: pixelsPerCm,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Fixed selection line with height display
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 24),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      selectedHeight.toInt().toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'cm',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.6,
                                      height: 2,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Continue button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveHeightToFirestore(); // Save height to Firestore
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BloodTypeSelectorPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Continue',
                        style: TextStyle(
                          color: Color(0xFF151515),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward,
                        color: Color(0xFF151515),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeightScalePainter extends CustomPainter {
  final double minHeight;
  final double maxHeight;
  final Color scaleColor;
  final double pixelsPerCm;

  HeightScalePainter({
    required this.minHeight,
    required this.maxHeight,
    required this.scaleColor,
    required this.pixelsPerCm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = scaleColor
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (double height = minHeight; height <= maxHeight; height += 1) {
      final y = (maxHeight - height) * pixelsPerCm;
      double lineLength = height % 10 == 0 ? 30.0 : (height % 5 == 0 ? 20.0 : 10.0);

      canvas.drawLine(Offset(size.width - lineLength, y), Offset(size.width, y), paint);

      if (height % 10 == 0) {
        textPainter.text = TextSpan(
          text: '${height.toInt()}',
          style: TextStyle(color: scaleColor, fontSize: 12),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(size.width - lineLength - textPainter.width - 5, y - textPainter.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
