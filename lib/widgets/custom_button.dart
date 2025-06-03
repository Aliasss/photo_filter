import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isLoading;
  final bool isSmall;
  final bool isDark;
  final double? width;
  final double? height;
  final IconData? icon;
  
  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.isSmall = false,
    this.isDark = false,
    this.width,
    this.height,
    this.icon,
  }) : super(key: key);
  
  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
    if (!widget.isLoading) {
      widget.onPressed();
    }
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.isLoading ? null : _onTapDown,
            onTapUp: widget.isLoading ? null : _onTapUp,
            onTapCancel: widget.isLoading ? null : _onTapCancel,
            child: Container(
              width: widget.width,
              height: widget.height ?? (widget.isSmall ? 36 : 48),
              decoration: BoxDecoration(
                color: widget.isOutlined 
                  ? Colors.transparent
                  : (widget.isDark ? Colors.white : AppColors.primary),
                borderRadius: BorderRadius.circular(widget.isSmall ? 10 : 12),
                border: widget.isOutlined
                    ? Border.all(
                        color: widget.isDark 
                          ? Colors.white.withOpacity(0.3) 
                          : AppColors.primary.withOpacity(0.3), 
                        width: 1.5
                      )
                    : null,
                boxShadow: widget.isOutlined 
                  ? null 
                  : AppColors.lightShadow,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.isSmall ? 10 : 12),
                  color: _isPressed 
                    ? AppColors.pressedOverlay
                    : null,
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: widget.isSmall ? 18 : 22,
                          height: widget.isSmall ? 18 : 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isOutlined 
                                ? (widget.isDark ? Colors.white : AppColors.primary)
                                : (widget.isDark ? AppColors.primary : Colors.white),
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(
                                widget.icon, 
                                size: widget.isSmall ? 16 : 20,
                                color: widget.isOutlined 
                                  ? (widget.isDark ? Colors.white : AppColors.primary)
                                  : (widget.isDark ? AppColors.primary : Colors.white),
                              ),
                              SizedBox(width: widget.isSmall ? 6 : 8),
                            ],
                            Text(
                              widget.text, 
                              style: (widget.isSmall 
                                ? AppTextStyles.buttonText.copyWith(fontSize: 13)
                                : AppTextStyles.buttonText).copyWith(
                                color: widget.isOutlined 
                                  ? (widget.isDark ? Colors.white : AppColors.primary)
                                  : (widget.isDark ? AppColors.primary : Colors.white),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
} 