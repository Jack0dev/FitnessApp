import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth/auth_service.dart';
import '../../services/user/data_service.dart';
import '../../services/user/role_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/design_tokens.dart';
import '../../widgets/widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _dataService = DataService();
  bool _isLoading = false;

  // Form controllers
  String? _selectedGender;
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String? _selectedJobNature;
  final _trainingFrequencyController = TextEditingController();
  final _trainingDurationController = TextEditingController();
  String? _selectedFitnessGoal;

  // Options
  final List<Map<String, String>> _genderOptions = [
    {'value': 'male', 'label': 'Nam'},
    {'value': 'female', 'label': 'Nữ'},
    {'value': 'other', 'label': 'Khác'},
  ];

  final List<Map<String, String>> _jobNatureOptions = [
    {'value': 'sedentary', 'label': 'Ít vận động (ngồi nhiều)'},
    {'value': 'light', 'label': 'Nhẹ nhàng (đi lại ít)'},
    {'value': 'moderate', 'label': 'Vừa phải (đi lại thường xuyên)'},
    {'value': 'active', 'label': 'Năng động (vận động nhiều)'},
    {'value': 'very_active', 'label': 'Rất năng động (lao động chân tay)'},
  ];

  final List<Map<String, String>> _fitnessGoalOptions = [
    {'value': 'muscle_gain', 'label': 'Tăng cơ'},
    {'value': 'fat_loss', 'label': 'Giảm mỡ'},
    {'value': 'endurance', 'label': 'Cải thiện sức bền'},
    {'value': 'strength', 'label': 'Tăng sức mạnh'},
    {'value': 'maintain', 'label': 'Giữ dáng'},
    {'value': 'other', 'label': 'Khác'},
  ];

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _trainingFrequencyController.dispose();
    _trainingDurationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw 'Người dùng chưa đăng nhập';
      }

      // Parse values
      final age = int.tryParse(_ageController.text);
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);
      final trainingFrequency = int.tryParse(_trainingFrequencyController.text);
      final trainingDuration = int.tryParse(_trainingDurationController.text);

      // Update user data
      await _dataService.updateUserData(
        userId: user.id,
        updateData: {
          'gender': _selectedGender,
          'age': age,
          'heightCm': height,
          'weightKg': weight,
          'jobNature': _selectedJobNature,
          'trainingFrequency': trainingFrequency,
          'trainingDurationMinutes': trainingDuration,
          'fitnessGoal': _selectedFitnessGoal,
          'profileCompleted': true,
        },
      );

      if (mounted) {
        // Get updated user data to determine route
        final userModel = await _dataService.getUserData(user.id);
        final route = userModel != null
            ? RoleService.getDashboardRoute(userModel)
            : AppRoutes.userDashboard;

        Navigator.of(context).pushReplacementNamed(route);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false, // Remove back button
        title: const CustomText(
          text: 'Thông tin cơ bản',
          variant: TextVariant.headlineMedium,
          color: DesignTokens.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingLG),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DesignTokens.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: DesignTokens.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 48,
                        color: DesignTokens.primary,
                      ),
                      const SizedBox(height: 16),
                      const CustomText(
                        text: 'Chào mừng bạn đến với Fitness App!',
                        variant: TextVariant.titleLarge,
                        color: DesignTokens.textDark,
                        fontWeight: FontWeight.bold,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      CustomText(
                        text: 'Vui lòng cung cấp một số thông tin cơ bản để chúng tôi có thể tạo chương trình tập luyện phù hợp nhất cho bạn.',
                        variant: TextVariant.bodyMedium,
                        color: DesignTokens.textSecondary,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingXL),

                // Gender
                CustomDropdown<String>(
                  label: 'Giới tính',
                  icon: Icons.person,
                  value: _selectedGender,
                  hint: 'Chọn giới tính',
                  items: _genderOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn giới tính';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.spacingMD),

                // Age
                CustomTextField(
                  label: 'Tuổi',
                  prefixIcon: Icons.cake_outlined,
                  suffixText: 'tuổi',
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tuổi';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return 'Vui lòng nhập tuổi hợp lệ (1-120)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.spacingMD),

                // Height and Weight in a row
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Chiều cao',
                        prefixIcon: Icons.height,
                        suffixText: 'cm',
                        controller: _heightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nhập chiều cao';
                          }
                          final height = double.tryParse(value);
                          if (height == null || height < 50 || height > 250) {
                            return 'Chiều cao hợp lệ: 50-250cm';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingMD),
                    Expanded(
                      child: CustomTextField(
                        label: 'Cân nặng',
                        prefixIcon: Icons.monitor_weight_outlined,
                        suffixText: 'kg',
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nhập cân nặng';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight < 10 || weight > 300) {
                            return 'Cân nặng hợp lệ: 10-300kg';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingMD),

                // Job Nature
                CustomDropdown<String>(
                  label: 'Tính chất công việc',
                  icon: Icons.work_outline,
                  value: _selectedJobNature,
                  hint: 'Chọn tính chất công việc',
                  items: _jobNatureOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedJobNature = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn tính chất công việc';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.spacingMD),

                // Training Frequency
                CustomTextField(
                  label: 'Tần suất tập luyện',
                  prefixIcon: Icons.calendar_today_outlined,
                  suffixText: 'buổi/tuần',
                  helperText: 'Bao nhiêu buổi tập mỗi tuần?',
                  controller: _trainingFrequencyController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tần suất tập luyện';
                    }
                    final freq = int.tryParse(value);
                    if (freq == null || freq < 0 || freq > 14) {
                      return 'Tần suất hợp lệ: 0-14 buổi/tuần';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.spacingMD),

                // Training Duration
                CustomTextField(
                  label: 'Thời lượng tập luyện',
                  prefixIcon: Icons.timer_outlined,
                  suffixText: 'phút/buổi',
                  helperText: 'Bao nhiêu phút mỗi buổi tập?',
                  controller: _trainingDurationController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập thời lượng tập luyện';
                    }
                    final duration = int.tryParse(value);
                    if (duration == null || duration < 0 || duration > 600) {
                      return 'Thời lượng hợp lệ: 0-600 phút';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.spacingMD),

                // Fitness Goal
                CustomDropdown<String>(
                  label: 'Mục tiêu tập luyện',
                  icon: Icons.flag_outlined,
                  value: _selectedFitnessGoal,
                  hint: 'Chọn mục tiêu của bạn',
                  items: _fitnessGoalOptions.map((option) {
                    return DropdownMenuItem<String>(
                      value: option['value'],
                      child: Text(option['label']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFitnessGoal = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng chọn mục tiêu tập luyện';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: DesignTokens.spacingXL),

                // Submit Button
                CustomButton(
                  label: 'Hoàn thành',
                  icon: Icons.check_circle_outline,
                  onPressed: _isLoading ? null : _submitForm,
                  variant: ButtonVariant.primary,
                  size: ButtonSize.large,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
                const SizedBox(height: DesignTokens.spacingMD),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

