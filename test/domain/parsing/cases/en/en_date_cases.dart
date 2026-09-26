import '../capture_case.dart';

/// English date examples (F4.6c). Clock: Sunday 13 September 2026, 14:32.
final enDateCases = <CaptureCase>[
  // --- relative days ------------------------------------------------------
  CaptureCase(
    'call mom today',
    title: 'Call mom',
    at: _sun13,
    tokens: ['date:today'],
  ),
  CaptureCase(
    'today pay the bill',
    title: 'Pay the bill',
    at: _sun13,
    tokens: ['date:today'],
  ),
  CaptureCase(
    'dentist tomorrow',
    title: 'Dentist',
    at: _mon14,
    tokens: ['date:tomorrow'],
  ),
  CaptureCase(
    'Tomorrow water the plants',
    title: 'Water the plants',
    at: _mon14,
    tokens: ['date:Tomorrow'],
  ),
  CaptureCase(
    'TOMORROW call the bank',
    title: 'Call the bank',
    at: _mon14,
    tokens: ['date:TOMORROW'],
  ),
  CaptureCase(
    'the day after tomorrow pick up the parcel',
    title: 'Pick up the parcel',
    at: _tue15,
    tokens: ['date:the day after tomorrow'],
  ),
  CaptureCase(
    'send the invoice day after tomorrow',
    title: 'Send the invoice',
    at: _tue15,
    tokens: ['date:day after tomorrow'],
  ),
  CaptureCase(
    'next week renew the subscription',
    title: 'Renew the subscription',
    at: DateTime(2026, 9, 20),
    tokens: ['date:next week'],
  ),
  CaptureCase(
    'car service next month',
    title: 'Car service',
    at: DateTime(2026, 10, 13),
    tokens: ['date:next month'],
  ),

  // --- weekdays -----------------------------------------------------------
  CaptureCase(
    'monday standup notes',
    title: 'Standup notes',
    at: _mon14,
    tokens: ['date:monday'],
  ),
  CaptureCase(
    'gym on tuesday',
    title: 'Gym',
    at: _tue15,
    tokens: ['date:on tuesday'],
  ),
  CaptureCase(
    'team lunch on Wednesday',
    title: 'Team lunch',
    at: DateTime(2026, 9, 16),
    tokens: ['date:on Wednesday'],
  ),
  CaptureCase(
    'thursday physio',
    title: 'Physio',
    at: DateTime(2026, 9, 17),
    tokens: ['date:thursday'],
  ),
  CaptureCase(
    'report due friday',
    title: 'Report due',
    at: _fri18,
    tokens: ['date:friday'],
  ),
  CaptureCase(
    'next friday haircut',
    title: 'Haircut',
    at: _fri18,
    tokens: ['date:next friday'],
  ),
  CaptureCase(
    'this friday cinema',
    title: 'Cinema',
    at: _fri18,
    tokens: ['date:this friday'],
  ),
  CaptureCase(
    'saturday clean the garage',
    title: 'Clean the garage',
    at: _sat19,
    tokens: ['date:saturday'],
  ),
  CaptureCase(
    'call grandma sunday',
    title: 'Call grandma',
    at: DateTime(2026, 9, 20),
    tokens: ['date:sunday'],
  ),
  CaptureCase(
    'on fri submit the form',
    title: 'Submit the form',
    at: _fri18,
    tokens: ['date:on fri'],
  ),
  CaptureCase(
    'next mon review the draft',
    title: 'Review the draft',
    at: _mon14,
    tokens: ['date:next mon'],
  ),
  CaptureCase(
    'on sat football',
    title: 'Football',
    at: _sat19,
    tokens: ['date:on sat'],
  ),
  CaptureCase(
    'this weekend paint the fence',
    title: 'Paint the fence',
    at: _sat19,
    tokens: ['date:this weekend'],
  ),
  CaptureCase(
    'weekend groceries run',
    title: 'Groceries run',
    at: _sat19,
    tokens: ['date:weekend'],
  ),
  CaptureCase(
    'on the weekend fix the shelf',
    title: 'Fix the shelf',
    at: _sat19,
    tokens: ['date:on the weekend'],
  ),
  CaptureCase(
    'by friday finish the slides',
    title: 'Finish the slides',
    at: _fri18,
    tokens: ['date:by friday'],
  ),

  // --- day of month -------------------------------------------------------
  CaptureCase(
    'pay the rent on the 17th',
    title: 'Pay the rent',
    at: DateTime(2026, 9, 17),
    tokens: ['date:on the 17th'],
  ),
  CaptureCase(
    'the 1st water bill',
    title: 'Water bill',
    at: DateTime(2026, 10, 1),
    tokens: ['date:the 1st'],
  ),
  CaptureCase(
    'car tax on the 31st',
    title: 'Car tax',
    at: DateTime(2026, 10, 31),
    tokens: ['date:on the 31st'],
  ),

  // --- named dates --------------------------------------------------------
  CaptureCase(
    'dentist on May 3',
    title: 'Dentist',
    at: DateTime(2027, 5, 3),
    tokens: ['date:on May 3'],
  ),
  CaptureCase(
    'May 3 dentist',
    title: 'Dentist',
    at: DateTime(2027, 5, 3),
    tokens: ['date:May 3'],
  ),
  CaptureCase(
    '3 May dentist',
    title: 'Dentist',
    at: DateTime(2027, 5, 3),
    tokens: ['date:3 May'],
  ),
  CaptureCase(
    'book the hall for May 3rd',
    title: 'Book the hall for',
    at: DateTime(2027, 5, 3),
    tokens: ['date:May 3rd'],
  ),
  CaptureCase(
    'anniversary on the 3rd of May',
    title: 'Anniversary',
    at: DateTime(2027, 5, 3),
    tokens: ['date:on the 3rd of May'],
  ),
  CaptureCase(
    'september 17 inspection',
    title: 'Inspection',
    at: DateTime(2026, 9, 17),
    tokens: ['date:september 17'],
  ),
  CaptureCase(
    'inspection on Sept 17',
    title: 'Inspection',
    at: DateTime(2026, 9, 17),
    tokens: ['date:on Sept 17'],
  ),
  CaptureCase(
    'conference on 1 January 2027',
    title: 'Conference',
    at: DateTime(2027, 1, 1),
    tokens: ['date:on 1 January 2027'],
  ),
  CaptureCase(
    'contract signed on May 3, 2027',
    title: 'Contract signed',
    at: DateTime(2027, 5, 3),
    tokens: ['date:on May 3, 2027'],
  ),
  CaptureCase(
    'leap check 29 February',
    title: 'Leap check',
    at: DateTime(2028, 2, 29),
    tokens: ['date:29 February'],
  ),
  CaptureCase(
    'invoice dated 3 March 2025',
    title: 'Invoice dated',
    at: DateTime(2025, 3, 3),
    past: true,
    tokens: ['date:3 March 2025'],
  ),

  // --- numeric dates (month/day for en_US) --------------------------------
  CaptureCase(
    'dentist 5/3',
    title: 'Dentist',
    at: DateTime(2027, 5, 3),
    tokens: ['date:5/3'],
  ),
  CaptureCase(
    'dentist 3/5',
    title: 'Dentist',
    at: DateTime(2027, 3, 5),
    tokens: ['date:3/5'],
  ),
  CaptureCase(
    'inspection 9/17',
    title: 'Inspection',
    at: DateTime(2026, 9, 17),
    tokens: ['date:9/17'],
  ),
  CaptureCase(
    'christmas dinner 25/12',
    title: 'Christmas dinner',
    at: DateTime(2026, 12, 25),
    tokens: ['date:25/12'],
  ),
  CaptureCase(
    'deadline 5/3/2027',
    title: 'Deadline',
    at: DateTime(2027, 5, 3),
    tokens: ['date:5/3/2027'],
  ),
  CaptureCase(
    'deadline 5/3/27',
    title: 'Deadline',
    at: DateTime(2027, 5, 3),
    tokens: ['date:5/3/27'],
  ),
  CaptureCase(
    'renew on 2027-05-03',
    title: 'Renew',
    at: DateTime(2027, 5, 3),
    tokens: ['date:on 2027-05-03'],
  ),

  // --- relative offsets ---------------------------------------------------
  CaptureCase(
    'follow up in 3 days',
    title: 'Follow up',
    at: DateTime(2026, 9, 16),
    tokens: ['date:in 3 days'],
  ),
  CaptureCase(
    'in three days water the plants',
    title: 'Water the plants',
    at: DateTime(2026, 9, 16),
    tokens: ['date:in three days'],
  ),
  CaptureCase(
    'review in 2 weeks',
    title: 'Review',
    at: DateTime(2026, 9, 27),
    tokens: ['date:in 2 weeks'],
  ),
  CaptureCase(
    'dentist in a month',
    title: 'Dentist',
    at: DateTime(2026, 10, 13),
    tokens: ['date:in a month'],
  ),
  CaptureCase(
    'call back in one week',
    title: 'Call back',
    at: DateTime(2026, 9, 20),
    tokens: ['date:in one week'],
  ),

  // --- combinations -------------------------------------------------------
  CaptureCase(
    'dentist tomorrow at 9',
    title: 'Dentist',
    at: DateTime(2026, 9, 14, 9),
    tokens: ['date:tomorrow', 'time:at 9'],
  ),
  CaptureCase(
    'team sync on friday at 6pm',
    title: 'Team sync',
    at: DateTime(2026, 9, 18, 18),
    tokens: ['date:on friday', 'time:at 6pm'],
  ),
  CaptureCase(
    'monday 9am kickoff',
    title: 'Kickoff',
    at: DateTime(2026, 9, 14, 9),
    tokens: ['date:monday', 'time:9am'],
  ),
  CaptureCase(
    'May 3 at 14:30 notary',
    title: 'Notary',
    at: DateTime(2027, 5, 3, 14, 30),
    tokens: ['date:May 3', 'time:at 14:30'],
  ),
];

final _sun13 = DateTime(2026, 9, 13);
final _mon14 = DateTime(2026, 9, 14);
final _tue15 = DateTime(2026, 9, 15);
final _fri18 = DateTime(2026, 9, 18);
final _sat19 = DateTime(2026, 9, 19);
