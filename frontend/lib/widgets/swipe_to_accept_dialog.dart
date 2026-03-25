import 'package:flutter/material.dart';
import 'package:swipeable_button_view/swipeable_button_view.dart';
import '../models/transformer.dart';
import '../providers/fault_provider.dart';
import '../providers/transformer_provider.dart';
import '../services/socket_service.dart';
import 'package:provider/provider.dart';

class SwipeToAcceptDialog extends StatefulWidget {
  final Transformer transformer;
  final SocketService socketService;

  const SwipeToAcceptDialog({Key? key, required this.transformer, required this.socketService}) : super(key: key);

  @override
  _SwipeToAcceptDialogState createState() => _SwipeToAcceptDialogState();
}

class _SwipeToAcceptDialogState extends State<SwipeToAcceptDialog> {
  bool isFinished = false;

  @override
  Widget build(BuildContext context) {
    // Check if the job was accepted by another engineer
    final provider = Provider.of<TransformerProvider>(context);
    if (provider.externallyAcceptedJobs.contains(widget.transformer.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Job was already accepted by another engineer.'),
              backgroundColor: Colors.blueGrey,
            ),
          );
        }
      });
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.redAccent.shade700,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 10,
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'EMERGENCY FAULT DETECTED',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              'A fuse has blown on ${widget.transformer.transformerId}!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${widget.transformer.location}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 48),
            
            // The Swipe Button
            SwipeableButtonView(
              buttonText: 'SWIPE TO ACCEPT JOB',
              buttonWidget: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey),
              activeColor: Colors.white,
              buttonColor: Colors.white,
              buttontextstyle: const TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: Colors.redAccent
              ),
              isFinished: isFinished,
              onWaitingProcess: () {
                Future.delayed(const Duration(seconds: 1), () {
                  setState(() {
                     isFinished = true;
                  });
                });
              },
              onFinish: () async {
                // Broadcast that this engineer accepted the job
                widget.socketService.acceptJob(widget.transformer.id);

                // When finished swiping, close the dialog
                if (mounted) Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Job accepted for ${widget.transformer.transformerId}. Please proceed to location.'),
                    backgroundColor: Colors.green,
                  )
                );
              },
            ),
            
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('DISMISS', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
