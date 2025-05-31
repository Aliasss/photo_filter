import 'package:flutter/material.dart';
import '../models/filter_option.dart';

class FilterOptionCard extends StatelessWidget {
  final FilterOption option;
  final VoidCallback onTap;

  const FilterOptionCard({
    super.key,
    required this.option,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            option.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
} 