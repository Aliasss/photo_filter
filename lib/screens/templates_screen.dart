import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/template.dart';
import '../widgets/custom_button.dart';
import 'image_adjustment_screen.dart';

class TemplatesScreen extends StatefulWidget {
  @override
  _TemplatesScreenState createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> with TickerProviderStateMixin {
  int _selectedCategoryIndex = 0;
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  
  // 🔥 미리보기 크기 상수화
  static const double PREVIEW_SIZE = 200.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TemplateCategory.categories.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedCategoryIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('템플릿', style: AppTextStyles.sectionTitle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.categoryDesc.copyWith(
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: AppTextStyles.categoryDesc,
              tabs: TemplateCategory.categories.map((category) {
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(category.icon, style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(category.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: TemplateCategory.categories.map((category) {
          return _buildTemplateGrid(category);
        }).toList(),
      ),
    );
  }

  Widget _buildTemplateGrid(TemplateCategory category) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 설명
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Text(category.icon, style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.name, style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 4),
                      Text(category.description, style: AppTextStyles.categoryDesc),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // 템플릿 그리드
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: category.templates.length,
              itemBuilder: (context, index) {
                final template = category.templates[index];
                return _buildTemplateCard(template);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Template template) {
    return GestureDetector(
      onTap: () => _selectTemplate(template),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 템플릿 미리보기
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildTemplatePreview(template),
                ),
              ),
            ),
            
            // 템플릿 정보
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: AppTextStyles.categoryDesc.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template.description,
                    style: AppTextStyles.categoryDesc.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 32,
                    child: CustomButton(
                      text: '선택',
                      onPressed: () => _selectTemplate(template),
                      isSmall: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePreview(Template template) {
    return AspectRatio(
      aspectRatio: template.aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: _getBackgroundColor(template.layout.background),
          gradient: _getBackgroundGradient(template.layout.background),
        ),
        child: Stack(
          children: template.elements.map((element) {
            return _buildElementPreview(element, template);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildElementPreview(TemplateElement element, Template template) {
    final bounds = element.bounds;
    
    return Positioned(
      left: bounds.left * PREVIEW_SIZE, // 🔥 상수 사용
      top: bounds.top * (PREVIEW_SIZE / template.aspectRatio),
      width: bounds.width * PREVIEW_SIZE,
      height: bounds.height * (PREVIEW_SIZE / template.aspectRatio),
      child: _buildElementWidget(element),
    );
  }

  Widget _buildElementWidget(TemplateElement element) {
    switch (element.type) {
      case TemplateElementType.userImage:
        return _buildUserImagePreview(element);
      
      case TemplateElementType.textOverlay:
        return _buildTextOverlayPreview(element);
      
      default:
        return Container();
    }
  }

  // 🔥 userImage 미리보기 개선
  Widget _buildUserImagePreview(TemplateElement element) {
    final style = element.style;
    final isCircle = style != null && style['shape'] == 'circle';
    final borderRadius = _getBorderRadius(style);
    final border = _getBorder(style);

    Widget preview = Container(
      decoration: BoxDecoration(
        // 🔥 그라데이션으로 더 예쁘게
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.border.withOpacity(0.3),
            AppColors.background.withOpacity(0.8),
          ],
        ),
        borderRadius: isCircle ? null : borderRadius,
        border: border,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.textSecondary,
          size: 28, // 아이콘 크기 증가
        ),
      ),
    );

    // 🔥 원형 클리핑 개선
    if (isCircle) {
      preview = ClipOval(child: preview);
    } else {
      preview = ClipRRect(
        borderRadius: borderRadius,
        child: preview,
      );
    }

    return preview;
  }

  // 🔥 textOverlay 미리보기 개선
  Widget _buildTextOverlayPreview(TemplateElement element) {
    final style = element.style;
    final textColor = _getTextColor(style);
    final backgroundColor = _getTextBackgroundColor(style);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        // 🔥 텍스트 영역에 약간의 그림자 추가
        boxShadow: backgroundColor != Colors.transparent ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ] : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Center(
        child: Text(
          'Text',
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w600, // 폰트 굵기 증가
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Color _getBackgroundColor(TemplateBackground background) {
    if (background.type == TemplateBackgroundType.color) {
      final colorString = background.value as String;
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    }
    return Colors.white;
  }

  Gradient? _getBackgroundGradient(TemplateBackground background) {
    if (background.type == TemplateBackgroundType.gradient) {
      final colors = background.value as List<String>;
      return LinearGradient(
        colors: colors.map((color) => 
          Color(int.parse(color.replaceFirst('#', '0xff')))
        ).toList(),
      );
    }
    return null;
  }

  // 🔥 BorderRadius 계산 개선
  BorderRadius _getBorderRadius(dynamic style) {
    try {
      if (style != null && style['shape'] == 'circle') {
        // 🔥 원형에 충분히 큰 값 사용
        return BorderRadius.circular(1000);
      } else if (style != null && style['borderRadius'] != null) {
        final radiusValue = style['borderRadius'];
        if (radiusValue is num && radiusValue.isFinite && radiusValue >= 0) {
          return BorderRadius.circular(radiusValue.toDouble());
        }
      }
    } catch (e) {
      print('BorderRadius 계산 오류: $e');
    }
    
    // 기본값
    return BorderRadius.circular(4);
  }

  BoxBorder? _getBorder(dynamic style) {
    if (style != null && style['borderWidth'] != null) {
      final borderColor = style['borderColor'] != null
        ? Color(int.parse(style['borderColor'].replaceFirst('#', '0xff')))
        : AppColors.border;
      return Border.all(
        color: borderColor,
        width: (style['borderWidth'] as int).toDouble(),
      );
    }
    return null;
  }

  Color _getTextBackgroundColor(dynamic style) {
    if (style != null && style['backgroundColor'] != null) {
      final colorString = style['backgroundColor'] as String;
      if (colorString.startsWith('rgba')) {
        return Colors.black.withOpacity(0.5);
      }
      // 🔥 색상 파싱 개선
      try {
        return Color(int.parse(colorString.replaceFirst('#', '0xff')));
      } catch (e) {
        print('backgroundColor 파싱 오류: $e');
        return Colors.black.withOpacity(0.5);
      }
    }
    return Colors.transparent;
  }

  Color _getTextColor(dynamic style) {
    if (style != null && style['textColor'] != null) {
      final colorString = style['textColor'] as String;
      try {
        return Color(int.parse(colorString.replaceFirst('#', '0xff')));
      } catch (e) {
        print('textColor 파싱 오류: $e');
        return AppColors.textPrimary;
      }
    }
    return AppColors.textPrimary;
  }

  Future<void> _selectTemplate(Template template) async {
    try {
      print('템플릿 선택: ${template.name}');
      
      // 이미지 선택 다이얼로그 표시
      final XFile? image = await _showImageSourceDialog();
      
      print('선택된 이미지: ${image?.path}');
      
      if (image != null) {
        print('이미지 조정 화면으로 이동');
        // 이미지 조정 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageAdjustmentScreen(
              template: template,
              userImage: image,
            ),
          ),
        );
      } else {
        print('이미지가 선택되지 않음');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지를 선택해주세요.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('템플릿 선택 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<XFile?> _showImageSourceDialog() async {
    if (kIsWeb) {
      // 웹에서는 갤러리만 표시
      return await _picker.pickImage(source: ImageSource.gallery);
    }

    return await showModalBottomSheet<XFile?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('이미지 선택', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 8),
            Text(
              '템플릿에 사용할 이미지를 선택해주세요.',
              style: AppTextStyles.categoryDesc,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: '카메라',
                    isOutlined: true,
                    icon: Icons.camera_alt,
                    onPressed: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.camera,
                      );
                      Navigator.pop(context, image);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: '갤러리',
                    icon: Icons.photo,
                    onPressed: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      Navigator.pop(context, image);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:image_picker/image_picker.dart';
// import '../constants/colors.dart';
// import '../constants/text_styles.dart';
// import '../models/template.dart';
// import '../widgets/custom_button.dart';
// import 'image_adjustment_screen.dart';

// class TemplatesScreen extends StatefulWidget {
//   @override
//   _TemplatesScreenState createState() => _TemplatesScreenState();
// }

// class _TemplatesScreenState extends State<TemplatesScreen> with TickerProviderStateMixin {
//   int _selectedCategoryIndex = 0;
//   late TabController _tabController;
//   final ImagePicker _picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(
//       length: TemplateCategory.categories.length,
//       vsync: this,
//     );
//     _tabController.addListener(() {
//       if (_tabController.indexIsChanging) {
//         setState(() {
//           _selectedCategoryIndex = _tabController.index;
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.surface,
//         elevation: 0,
//         title: Text('템플릿', style: AppTextStyles.sectionTitle),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
//           onPressed: () => Navigator.pop(context),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(48),
//           child: Container(
//             color: AppColors.surface,
//             child: TabBar(
//               controller: _tabController,
//               indicatorColor: AppColors.primary,
//               labelColor: AppColors.primary,
//               unselectedLabelColor: AppColors.textSecondary,
//               labelStyle: AppTextStyles.categoryDesc.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//               unselectedLabelStyle: AppTextStyles.categoryDesc,
//               tabs: TemplateCategory.categories.map((category) {
//                 return Tab(
//                   child: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(category.icon, style: TextStyle(fontSize: 16)),
//                       const SizedBox(width: 8),
//                       Text(category.name),
//                     ],
//                   ),
//                 );
//               }).toList(),
//             ),
//           ),
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: TemplateCategory.categories.map((category) {
//           return _buildTemplateGrid(category);
//         }).toList(),
//       ),
//     );
//   }

//   Widget _buildTemplateGrid(TemplateCategory category) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // 카테고리 설명
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: AppColors.border),
//             ),
//             child: Row(
//               children: [
//                 Text(category.icon, style: TextStyle(fontSize: 24)),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(category.name, style: AppTextStyles.sectionTitle),
//                       const SizedBox(height: 4),
//                       Text(category.description, style: AppTextStyles.categoryDesc),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 20),
          
//           // 템플릿 그리드
//           Expanded(
//             child: GridView.builder(
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 2,
//                 crossAxisSpacing: 16,
//                 mainAxisSpacing: 16,
//                 childAspectRatio: 0.8,
//               ),
//               itemCount: category.templates.length,
//               itemBuilder: (context, index) {
//                 final template = category.templates[index];
//                 return _buildTemplateCard(template);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTemplateCard(Template template) {
//     return GestureDetector(
//       onTap: () => _selectTemplate(template),
//       child: Container(
//         decoration: BoxDecoration(
//           color: AppColors.surface,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: AppColors.border),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Column(
//           children: [
//             // 템플릿 미리보기
//             Expanded(
//               child: Container(
//                 margin: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: AppColors.border),
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: _buildTemplatePreview(template),
//                 ),
//               ),
//             ),
            
//             // 템플릿 정보
//             Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     template.name,
//                     style: AppTextStyles.categoryDesc.copyWith(
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     template.description,
//                     style: AppTextStyles.categoryDesc.copyWith(
//                       fontSize: 12,
//                       color: AppColors.textSecondary,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     width: double.infinity,
//                     height: 32,
//                     child: CustomButton(
//                       text: '선택',
//                       onPressed: () => _selectTemplate(template),
//                       isSmall: true,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTemplatePreview(Template template) {
//     return AspectRatio(
//       aspectRatio: template.aspectRatio,
//       child: Container(
//         decoration: BoxDecoration(
//           color: _getBackgroundColor(template.layout.background),
//           gradient: _getBackgroundGradient(template.layout.background),
//         ),
//         child: Stack(
//           children: template.elements.map((element) {
//             return _buildElementPreview(element, template);
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildElementPreview(TemplateElement element, Template template) {
//     final bounds = element.bounds;
    
//     return Positioned(
//       left: bounds.left * 200, // 미리보기 크기에 맞게 조정
//       top: bounds.top * (200 / template.aspectRatio),
//       width: bounds.width * 200,
//       height: bounds.height * (200 / template.aspectRatio),
//       child: _buildElementWidget(element),
//     );
//   }

//   Widget _buildElementWidget(TemplateElement element) {
//     switch (element.type) {
//       case TemplateElementType.userImage:
//         return Container(
//           decoration: BoxDecoration(
//             color: AppColors.border,
//             borderRadius: _getBorderRadius(element.style),
//             border: _getBorder(element.style),
//           ),
//           child: Icon(
//             Icons.image,
//             color: AppColors.textSecondary,
//             size: 24,
//           ),
//         );
      
//       case TemplateElementType.textOverlay:
//         return Container(
//           decoration: BoxDecoration(
//             color: _getTextBackgroundColor(element.style),
//             borderRadius: BorderRadius.circular(4),
//           ),
//           padding: const EdgeInsets.all(4),
//           child: Text(
//             'Text',
//             style: TextStyle(
//               color: _getTextColor(element.style),
//               fontSize: 10,
//               fontWeight: FontWeight.w500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         );
      
//       default:
//         return Container();
//     }
//   }

//   Color _getBackgroundColor(TemplateBackground background) {
//     if (background.type == TemplateBackgroundType.color) {
//       final colorString = background.value as String;
//       return Color(int.parse(colorString.replaceFirst('#', '0xff')));
//     }
//     return Colors.white;
//   }

//   Gradient? _getBackgroundGradient(TemplateBackground background) {
//     if (background.type == TemplateBackgroundType.gradient) {
//       final colors = background.value as List<String>;
//       return LinearGradient(
//         colors: colors.map((color) => 
//           Color(int.parse(color.replaceFirst('#', '0xff')))
//         ).toList(),
//       );
//     }
//     return null;
//   }

//   BorderRadius _getBorderRadius(dynamic style) {
//     if (style != null && style['shape'] == 'circle') {
//       return BorderRadius.circular(100);
//     } else if (style != null && style['borderRadius'] != null) {
//       return BorderRadius.circular(style['borderRadius'].toDouble());
//     }
//     return BorderRadius.circular(4);
//   }

//   BoxBorder? _getBorder(dynamic style) {
//     if (style != null && style['borderWidth'] != null) {
//       final borderColor = style['borderColor'] != null
//         ? Color(int.parse(style['borderColor'].replaceFirst('#', '0xff')))
//         : AppColors.border;
//       return Border.all(
//         color: borderColor,
//         width: (style['borderWidth'] as int).toDouble(),
//       );
//     }
//     return null;
//   }

//   Color _getTextBackgroundColor(dynamic style) {
//     if (style != null && style['backgroundColor'] != null) {
//       final colorString = style['backgroundColor'] as String;
//       if (colorString.startsWith('rgba')) {
//         return Colors.black.withOpacity(0.5);
//       }
//     }
//     return Colors.transparent;
//   }

//   Color _getTextColor(dynamic style) {
//     if (style != null && style['textColor'] != null) {
//       final colorString = style['textColor'] as String;
//       return Color(int.parse(colorString.replaceFirst('#', '0xff')));
//     }
//     return AppColors.textPrimary;
//   }

//   Future<void> _selectTemplate(Template template) async {
//     try {
//       print('템플릿 선택: ${template.name}');
      
//       // 이미지 선택 다이얼로그 표시
//       final XFile? image = await _showImageSourceDialog();
      
//       print('선택된 이미지: ${image?.path}');
      
//       if (image != null) {
//         print('이미지 조정 화면으로 이동');
//         // 이미지 조정 화면으로 이동
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ImageAdjustmentScreen(
//               template: template,
//               userImage: image,
//             ),
//           ),
//         );
//       } else {
//         print('이미지가 선택되지 않음');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('이미지를 선택해주세요.'),
//             backgroundColor: Colors.orange,
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//     } catch (e) {
//       print('템플릿 선택 오류: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('오류가 발생했습니다: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 3),
//         ),
//       );
//     }
//   }

//   Future<XFile?> _showImageSourceDialog() async {
//     if (kIsWeb) {
//       // 웹에서는 갤러리만 표시
//       return await _picker.pickImage(source: ImageSource.gallery);
//     }

//     return await showModalBottomSheet<XFile?>(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: AppColors.border,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text('이미지 선택', style: AppTextStyles.sectionTitle),
//             const SizedBox(height: 8),
//             Text(
//               '템플릿에 사용할 이미지를 선택해주세요.',
//               style: AppTextStyles.categoryDesc,
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
//             Row(
//               children: [
//                 Expanded(
//                   child: CustomButton(
//                     text: '카메라',
//                     isOutlined: true,
//                     icon: Icons.camera_alt,
//                     onPressed: () async {
//                       final XFile? image = await _picker.pickImage(
//                         source: ImageSource.camera,
//                       );
//                       Navigator.pop(context, image);
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: CustomButton(
//                     text: '갤러리',
//                     icon: Icons.photo,
//                     onPressed: () async {
//                       final XFile? image = await _picker.pickImage(
//                         source: ImageSource.gallery,
//                       );
//                       Navigator.pop(context, image);
//                     },
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
// } 