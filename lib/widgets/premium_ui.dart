import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../utils/style_constants.dart';

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool secondary;

  const PremiumButton({
    super.key, 
    required this.text, 
    required this.onPressed, 
    this.isLoading = false,
    this.icon,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: secondary ? null : AshallTheme.buttonDecoration,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary ? Colors.white : Colors.transparent,
          foregroundColor: secondary ? AshallTheme.primaryColor : Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: secondary ? const BorderSide(color: AshallTheme.primaryColor) : BorderSide.none,
          ),
          elevation: 0,
        ),
        child: isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon), const SizedBox(width: 10)],
                Text(text, style: GoogleFonts.cairo(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
      ),
    );
  }
}

class PremiumTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool isPassword;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? hint;
  final Widget? suffix;
  final void Function(String)? onChanged;
  final int maxLines;

  const PremiumTextField({
    super.key, 
    required this.label, 
    required this.controller, 
    this.isPassword = false, 
    this.icon,
    this.keyboardType,
    this.hint,
    this.suffix,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        onChanged: onChanged,
        maxLines: maxLines,
        style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: AshallTheme.primaryColor) : null,
          suffixIcon: suffix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final double borderRadius;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key, 
    required this.child, 
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderRadius = 24,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: child,
      ),
    );
  }
}

class PremiumBadge extends StatelessWidget {
  final String text;
  final Color color;
  const PremiumBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsets? padding;

  const GlassContainer({
    super.key, 
    required this.child, 
    this.blur = 10, 
    this.opacity = 0.1,
    this.borderRadius = 24,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class PremiumSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionText;
  final VoidCallback? onAction;
  final IconData? icon;

  const PremiumSectionTitle({
    super.key, 
    required this.title, 
    this.subtitle,
    this.actionText, 
    this.onAction,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AshallTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.cairo(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (actionText != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionText!,
                style: GoogleFonts.cairo(
                  color: AshallTheme.secondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PremiumAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;

  const PremiumAvatar({
    super.key, 
    this.imageUrl, 
    required this.name, 
    this.size = 50,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AshallTheme.premiumGradient,
            boxShadow: [
              BoxShadow(
                color: AshallTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
              child: imageUrl == null 
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: TextStyle(fontWeight: FontWeight.bold, color: AshallTheme.primaryColor, fontSize: size * 0.4))
                : null,
            ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              height: size * 0.25,
              width: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class PremiumSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const PremiumSkeleton({super.key, this.width, this.height, this.borderRadius = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!],
          stops: const [0.1, 0.5, 0.9],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const InteractiveCard({super.key, required this.child, this.onTap});

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: PremiumCard(
          padding: EdgeInsets.zero,
          child: widget.child,
        ),
      ),
    );
  }
}

class ConfettiCelebration extends StatelessWidget {
  const ConfettiCelebration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(50, (i) => Positioned(
        top: -10,
        left: (i * 20).toDouble() % MediaQuery.of(context).size.width,
        child: _ConfettiPiece(index: i),
      )),
    );
  }
}

class _ConfettiPiece extends StatefulWidget {
  final int index;
  const _ConfettiPiece({required this.index});

  @override
  State<_ConfettiPiece> createState() => _ConfettiPieceState();
}

class _ConfettiPieceState extends State<_ConfettiPiece> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _y;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: 1500 + (widget.index * 50)));
    _y = Tween<double>(begin: -10, end: 800).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _color = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.orange, Colors.purple][widget.index % 6];
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Transform.translate(
        offset: Offset(0, _y.value),
        child: Transform.rotate(
          angle: _ctrl.value * 10,
          child: Container(width: 8, height: 8, color: _color),
        ),
      ),
    );
  }
}

class PremiumQuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const PremiumQuickAction({
    super.key, 
    required this.label, 
    required this.icon, 
    required this.color, 
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}


