import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_week_view/flutter_week_view.dart';
import 'package:split_view/split_view.dart';

import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as picker;
import 'package:time_boxing/DB/database.dart';
import 'package:time_boxing/home_steps/data/PlanTime.dart';

class PlanView extends StatefulWidget {
  final List<String> nameList;
  final List<String> priority;
  final Map<String, DateTime> startTime;
  final Map<String, DateTime> endTime;
  final List<PlanTime> planList;
  final PageController pc;
  final bool isEdit;

  const PlanView({super.key, required this.nameList, required this.priority, required this.startTime, required this.endTime, required this.planList, required this.pc, required this.isEdit});

  @override
  State<PlanView> createState() => _PlanViewState();
}

class _PlanViewState extends State<PlanView> {
  Mydatabase db = Mydatabase.instance;

  bool isDarkMode = false;
  
  GlobalKey gk = GlobalKey();
  GlobalKey listGK = GlobalKey();

  List<Color> colors = [const Color.fromARGB(255, 171, 222, 230), const Color.fromARGB(255, 203, 170, 203), const Color.fromARGB(255, 255, 204, 182), const Color.fromARGB(255, 243, 176, 195)];
  final random = Random();
  List<ExpansionTileController> expansionControllers = [];
  ScrollController scrollController = ScrollController();
  
  List<double> splitWeights = [0.6, 0.4];
  SplitViewController splitController = SplitViewController(weights: [0.6, 0.4]);
  
  bool isMoving = false;

  DragStartingGesture dg = DragStartingGesture.longPress;

  final darkTheme = const picker.DatePickerTheme(
    headerColor: Colors.black87,
    backgroundColor: Colors.black87,
    itemStyle: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 18
    ),
    cancelStyle: TextStyle(color: Colors.white, fontSize: 16),
    doneStyle: TextStyle(color: Colors.blue, fontSize: 16)
  );

  int checkPrioritySet() {
    int idx = 1;
    for(final p in widget.priority) {
      PlanTime item = PlanTime(title: p, description: "", start: DateTime.now(), end: DateTime.now());
      if(!widget.planList.contains(item)) return idx;
      idx++;
    }

    return widget.nameList.length;
  }

  void appendPlan(String name) {
    PlanTime item = PlanTime(title: name, description: "", start: widget.startTime[name]!, end: widget.endTime[name]!, backgroundColor: colors[random.nextInt(colors.length)]);
    setState(() {
      if(widget.planList.contains(item)) {
        widget.planList.remove(item);
      }
      widget.planList.add(item);
    });
  }

  Future<void> showDialogAndSelectTime(String name, Map<String, DateTime> timeMap, void Function(DateTime) callback) async {
    DateTime now = (timeMap.containsKey(name)) ? timeMap[name]! : DateTime.now();
    DateTime? selectedTime = await picker.DatePicker.showTime12hPicker(context, currentTime: now, theme: (isDarkMode) ? darkTheme : null);
    if(selectedTime != null) {
      callback(selectedTime);
    }
  }

  Widget getExpansionTile(int index) {
    return ExpansionTile(
      initiallyExpanded: (widget.planList.contains(PlanTime(title: widget.nameList[index], description: "", start: DateTime.now(), end: DateTime.now()))) ? false : true,
      shape: const Border(),
      controller: expansionControllers[index],
      title: Padding(padding: const EdgeInsets.only(left: 10), child: Text(widget.nameList[index], style: const TextStyle(fontSize: 21))),
      children: [
        Padding(padding: const EdgeInsets.all(5),
          child: SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                // 시작 시간 설정 버튼
                Expanded(
                  child: TextButton(
                    onPressed: () => showDialogAndSelectTime(widget.nameList[index], widget.startTime, (selectedTime) => setState(() {
                        widget.startTime[widget.nameList[index]] = selectedTime;

                        if(!widget.endTime.containsKey(widget.nameList[index]) || widget.endTime[widget.nameList[index]]!.isBefore(selectedTime)) {
                          widget.endTime[widget.nameList[index]] = selectedTime.add(const Duration(hours: 1));
                        }
                      })
                    ),
                    child: widget.startTime.containsKey(widget.nameList[index]) ? Text("${widget.startTime[widget.nameList[index]]!.hour.toString().padLeft(2, '0')} : ${widget.startTime[widget.nameList[index]]!.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 20),) : const Text("시작 시간", style: TextStyle(fontSize: 20))
                  )
                ),

                // 끝 시간 설정 버튼
                Expanded(
                  child: TextButton(
                    onPressed: () => showDialogAndSelectTime(widget.nameList[index], widget.endTime, (selectedTime) => setState(() {
                        widget.endTime[widget.nameList[index]] = selectedTime;

                        if(!widget.startTime.containsKey(widget.nameList[index]) || selectedTime.isBefore(widget.startTime[widget.nameList[index]]!)) {
                          widget.startTime[widget.nameList[index]] = selectedTime.subtract(const Duration(hours: 1));
                        }
                      })
                    ),
                    child: widget.endTime.containsKey(widget.nameList[index]) ? Text("${widget.endTime[widget.nameList[index]]!.hour.toString().padLeft(2, '0')} : ${widget.endTime[widget.nameList[index]]!.minute.toString().padLeft(2, '0')}", style: const TextStyle(fontSize: 20)) : const Text("끝 시간", style: TextStyle(fontSize: 20))
                  )
                ),

                // 완료 버튼
                Expanded(
                  child: TextButton(
                    onPressed:() {
                      String name = widget.nameList[index];
                      if(widget.startTime.containsKey(name) && widget.endTime.containsKey(name)) {
                        appendPlan(name);
                        expansionControllers[index].collapse();
                        if(widget.startTime.length == 3 && widget.endTime.length == 3) {
                          RenderBox listRB = listGK.currentContext!.findRenderObject() as RenderBox;
                          RenderBox rb = gk.currentContext!.findRenderObject() as RenderBox;

                          double move = scrollController.offset + (rb.size.height * 3 + rb.size.height * 2 * (widget.nameList.length - 3) - listRB.size.height);
                          if(listRB.size.height <= rb.size.height * 2 * (widget.nameList.length - 3)) {
                            move = rb.size.height * 3;
                          }
                          
                          scrollController.animateTo(move, duration: const Duration(microseconds: 500), curve: Curves.ease);
                        }
                      }
                    },
                    child: const Text("완료", style: TextStyle(fontSize: 20))
                  )
                )
              ],
            )
          )
        )
      ]
    );
  }

  @override
  void initState() {
    // 키보드 숨기기
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    
    // Expansion 컨트롤러 생성
    expansionControllers = List<ExpansionTileController>.generate(widget.nameList.length, (index) => ExpansionTileController());
    
    // 데스크톱 OS에서는 tap으로 드래그 & 드롭
    if(Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      dg = DragStartingGesture.tap;
    }

    // 다크모드 설정 변수
    var brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
    isDarkMode = (brightness == Brightness.dark);
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    // 우선순위 지정된 일정은 nameList에서 제거
    for(final p in widget.priority) {
      widget.nameList.remove(p);
    }

    // nameList의 첫 번째 부분에 우선순위 일정 삽입
    widget.nameList.insertAll(0, widget.priority);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Step 3: Planning"),
        centerTitle: true,
        backgroundColor: Colors.pink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            widget.pc.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.ease);
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 10,
            child: SplitView(
              controller: splitController,
              viewMode: SplitViewMode.Vertical,
              indicator: const SplitIndicator(viewMode: SplitViewMode.Vertical),
              onWeightChanged: (value) {
                if(!isMoving) {
                  splitWeights = List.of(value).map((d) => d!).toList();
                }
              },
              gripColor: (isDarkMode) ? Colors.black12 : Colors.grey,
              gripColorActive: (isDarkMode) ? Colors.black12 : Colors.grey,
              children: [
                Container(
                  child: DayView(
                    currentTimeIndicatorBuilder: (_, __, ___, ____) {},
                    userZoomable: false,
                    events: widget.planList,
                    date: DateTime.now(),
                    style: const DayViewStyle(headerSize: 0),
                    // 드래그 앤 드랍으로 일정 이동
                    dragAndDropOptions: DragAndDropOptions(
                      startingGesture: dg,
                      onEventMove: (event, _) {
                        setState(() {
                          isMoving = true;
                          splitController.weights = [1.0, 0.0];
                        });
                      },
                      onEventDragged:(event, newStartTime) {
                        final dur = event.end.subtract(Duration(hours: event.start.hour, minutes: event.start.minute));
                        event.start = newStartTime;
                        event.end = event.start.add(Duration(hours: dur.hour, minutes: dur.minute));
                        widget.startTime[event.title] = event.start;
                        widget.endTime[event.title] = event.end;
                        
                        setState(() {
                          isMoving = false;
                          splitController.weights = splitWeights;
                        });
                      },
                    ),
                    // 드래그 앤 드랍으로 일정 길이 수정
                    resizeEventOptions: ResizeEventOptions(
                      snapToGridGranularity: const Duration(minutes: 15),
                      onEventResizeMove: (event, newEndTime) {
                        setState(() {
                          isMoving = true;
                          splitController.weights = [1.0, 0.0];
                        });
                      },
                      onEventResized: (event, newEndTime) {
                        event.end = newEndTime;
                        widget.endTime[event.title] = event.end;
                        
                        setState(() {
                          isMoving = false;
                          splitController.weights = splitWeights;
                        });
                      },
                    ),
                  ),
                ),
                
                Container(
                  key: listGK,
                  decoration: BoxDecoration(
                    color: (isDarkMode) ? Colors.black12 : Colors.grey
                  ),
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    controller: scrollController,
                    padding: const EdgeInsets.all(3),
                    itemCount: checkPrioritySet(),
                    itemBuilder: (BuildContext context, int index) {
                      return Card(
                        key: (index == 0) ? gk : null,
                        child: getExpansionTile(index),
                      );
                    }
                  ),
                )
              ]
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  // 예외 처리
                  if(widget.planList.length != widget.nameList.length) {
                    await showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text('Alert'),
                          content: const Text('모든 일정의 시간을 작성하세요.'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('확인'),
                            ),
                          ],
                        );
                      }
                    );

                    return;
                  }

                  // DB 저장
                  DateTime now = DateTime.now();
                  DateTime onlyDate = DateTime(now.year, now.month, now.day);
                  
                  if(widget.isEdit) {
                    await db.timeBoxingRepository.updateTimeBoxing(onlyDate);
                  } else {
                    final recentZandi = await db.zandiRepository.selectRecentData();
                    // 마지막 잔디가 어제일 때(스택 + 1)
                    if(recentZandi[0].date.compareTo(onlyDate.subtract(const Duration(days: 1))) == 0) {
                      await db.zandiRepository.updateZandiInfo(recentZandi[0].date, recentZandi[0].stack + 1);
                    } else if(recentZandi[0].date.compareTo(onlyDate) == 0 && recentZandi[0].stack == 0) { // 오늘이고 스택 0일 때
                      await db.zandiRepository.updateZandiInfo(recentZandi[0].date, recentZandi[0].stack + 1);
                    } else { // 아니면 오늘 추가
                      await db.zandiRepository.insertZaniInfo(onlyDate);
                    }
                  }

                  for(final item in widget.planList) {
                    int st = item.start.hour * 60 + item.start.minute;
                    int end = item.end.hour * 60 + item.end.minute;
                    await db.timeBoxingRepository.insertTimeBoxing(onlyDate, item.title, widget.priority.indexOf(item.title), st, end);
                  }

                  // 초기화면으로 돌아감
                  if(context.mounted) {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                },
                child: const Text("저장")
              )
            )
          )
        ]
      )
    );
  }
}