import 'dart:math';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dragdrop/my_draggable_widget.dart';
import 'package:flutter_dragdrop/my_drop_region.dart';

import 'type.dart';

class SplitPanels extends StatefulWidget {
  const SplitPanels({super.key, this.columns = 5, this.itemSpacing = 4.0});

  final int columns;
  final double itemSpacing;

  @override
  State<SplitPanels> createState() => _SplitPanelsState();
}

class _SplitPanelsState extends State<SplitPanels> {
  final List<String> upper = [];
  final List<String> lower = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];

  PanelLocation? dragStart;
  PanelLocation? dropPreview;
  String? hoveringData;

  void onDragStart(PanelLocation start) {
    final data = switch (start.$2) {
      Panel.lower => lower[start.$1],
      Panel.upper => upper[start.$1],
    };

    setState(() {
      dragStart = start;
      hoveringData = data;
    });
  }

  void drop() {
    assert(dropPreview != null, 'Can only drop over a known location');
    assert(hoveringData != null, 'Can only drop when data is being dragged');
    setState(() {
      if (dragStart != null) {
        if (dragStart!.$2 == Panel.upper) {
          upper.removeAt(dragStart!.$1);
        } else {
          lower.removeAt(dragStart!.$1);
        }
      }
      if (dropPreview!.$2 == Panel.upper) {
        upper.insert(min(dropPreview!.$1, upper.length), hoveringData!);
      } else {
        lower.insert(min(dropPreview!.$1, upper.length), hoveringData!);
      }

      dragStart = null;
      dropPreview = null;
      hoveringData = null;
    });
  }

  void updateDropPreview(PanelLocation update) =>
      setState(() => dropPreview = update);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final gutters = widget.columns + 1;
      final spaceForColumns =
          constraints.maxWidth - (gutters * widget.itemSpacing);
      final columnWidth = spaceForColumns / widget.columns;
      final itemSize = Size(columnWidth, columnWidth);

      return Stack(
        children: <Widget>[
          Positioned(
            height: constraints.maxHeight / 2,
            width: constraints.maxWidth,
            top: 0,
            child: MyDropRegion(
              onDrop: drop,
              updateDropPreview: updateDropPreview,
              columns: widget.columns,
              childSize: itemSize,
              panel: Panel.upper,
              child: ItemPanel(
                crossAxisCount: widget.columns,
                dragStart: dragStart?.$2 == Panel.upper ? dragStart : null,
                dropPreview:
                    dropPreview?.$2 == Panel.upper ? dropPreview : null,
                hoveringData:
                    dropPreview?.$2 == Panel.upper ? hoveringData : null,
                items: upper,
                onDragStart: onDragStart,
                panel: Panel.upper,
                spacing: widget.itemSpacing,
              ),
            ),
          ),
          Positioned(
            height: 2,
            width: constraints.maxWidth,
            top: constraints.maxHeight / 2,
            child: const ColoredBox(color: Colors.black),
          ),
          Positioned(
            height: constraints.maxHeight / 2,
            width: constraints.maxWidth,
            bottom: 0,
            child: MyDropRegion(
              onDrop: drop,
              updateDropPreview: updateDropPreview,
              columns: widget.columns,
              childSize: itemSize,
              panel: Panel.lower,
              child: ItemPanel(
                crossAxisCount: widget.columns,
                dragStart: dragStart?.$2 == Panel.lower ? dragStart : null,
                dropPreview:
                    dropPreview?.$2 == Panel.lower ? dropPreview : null,
                hoveringData:
                    dropPreview?.$2 == Panel.lower ? hoveringData : null,
                items: lower,
                onDragStart: onDragStart,
                panel: Panel.lower,
                spacing: widget.itemSpacing,
              ),
            ),
          ),
        ],
      );
    });
  }
}

class ItemPanel extends StatelessWidget {
  const ItemPanel(
      {super.key,
      required this.crossAxisCount,
      required this.dragStart,
      required this.dropPreview,
      required this.hoveringData,
      required this.items,
      required this.onDragStart,
      required this.panel,
      required this.spacing});

  final int crossAxisCount;
  final PanelLocation? dragStart;
  final PanelLocation? dropPreview;
  final String? hoveringData;
  final List<String> items;
  final double spacing;

  final Function(PanelLocation) onDragStart;
  final Panel panel;

  @override
  Widget build(BuildContext context) {
    final itemsCopy = List<String>.from(items);
    PanelLocation? dragStartCopy;
    PanelLocation? dropPreviewCopy;
    if (dragStart != null) {
      dragStartCopy = dragStart!.copyWith();
    }

    if (dropPreview != null && hoveringData != null) {
      dropPreviewCopy = dropPreview!.copyWith(
        index: min(items.length, dropPreview!.$1),
      );
      if (dragStartCopy?.$2 == dropPreviewCopy.$2) {
        itemsCopy.removeAt(dragStartCopy!.$1);
        dragStartCopy = null;
      }
      itemsCopy.insert(min(dropPreview!.$1, itemsCopy.length), hoveringData!);
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      padding: const EdgeInsets.all(4),
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      children:
          itemsCopy.asMap().entries.map<Widget>((MapEntry<int, String> entry) {
        Color textColor =
            entry.key == dragStartCopy?.$1 || entry.key == dropPreviewCopy?.$1
                ? Colors.grey
                : Colors.white;

        Widget child = Center(
          child: Text(entry.value,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 36, color: textColor)),
        );

        if (entry.key == dragStartCopy?.$1) {
          child = Container(
              height: 200,
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.all(Radius.circular(8))),
              child: child);
        } else if (entry.key == dropPreviewCopy?.$1) {
          child = DottedBorder(
            color: Colors.grey,
            strokeWidth: 2,
            borderType: BorderType.RRect,
            dashPattern: const [10, 10],
            radius: const Radius.circular(20),
            child: child,
          );
        } else {
          child = Container(
              height: 200,
              decoration: const BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.all(Radius.circular(8))),
              child: child);
        }

        return Draggable(
          feedback: child,
          child: MyDraggableWidget(
            data: entry.value,
            onDragStart: () => onDragStart((entry.key, panel)),
            child: child,
          ),
        );
      }).toList(),
    );
  }
}
