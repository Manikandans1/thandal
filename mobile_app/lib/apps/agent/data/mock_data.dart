import '../models/models.dart';

/// "Today" is pinned so the prototype always reads the same way the
/// original design does (Sat 19 Sep).
final DateTime kToday = DateTime(2026, 9, 19);

final Agent kAgent = Agent(
  name: 'Karthik R',
  agentId: 'AGT-007',
  phone: '+91 98410 22017',
);

List<ScheduleDay> _buildSchedule({
  required DateTime start,
  required ChitFrequency freq,
  required int total,
  required double amount,
  required int paid,
  int overdueCount = 0,
}) {
  Duration step;
  switch (freq) {
    case ChitFrequency.daily:
      step = const Duration(days: 1);
      break;
    case ChitFrequency.weekly:
      step = const Duration(days: 7);
      break;
    case ChitFrequency.monthly:
      step = const Duration(days: 30);
      break;
  }
  final days = <ScheduleDay>[];
  for (var i = 0; i < total; i++) {
    final date = start.add(step * i);
    InstallmentStatus status;
    if (i < paid) {
      status = InstallmentStatus.paid;
    } else if (i < paid + overdueCount) {
      status = InstallmentStatus.overdue;
    } else if (i == paid + overdueCount) {
      status = InstallmentStatus.today;
    } else {
      status = InstallmentStatus.pending;
    }
    days.add(ScheduleDay(index: i + 1, date: date, amount: amount, status: status));
  }
  return days;
}

List<Customer> buildMockCustomers() {
  final customers = <Customer>[];

  customers.add(Customer(
    customerCode: 'THD-10311',
    name: 'Anwar Basha',
    phone: '+91 90031 55870',
    address: '27, Ambedkar Street',
    customerSince: DateTime(2026, 7, 2),
    idProofType: 'Voter ID',
    idProofLast4: '3346',
    chits: [
      Chit(
        chitCode: 'THD-1033',
        loanAmount: 12000,
        installmentAmount: 150,
        frequency: ChitFrequency.daily,
        totalInstallments: 100,
        startDate: DateTime(2026, 7, 27),
        installmentsPaid: 52,
        schedule: _buildSchedule(
          start: DateTime(2026, 7, 27),
          freq: ChitFrequency.daily,
          total: 100,
          amount: 150,
          paid: 52,
          overdueCount: 2,
        ),
      ),
    ],
  ));

  customers.add(Customer(
    customerCode: 'THD-10420',
    name: 'Balaji K',
    phone: '+91 98450 12233',
    address: '14, Temple Street',
    customerSince: DateTime(2026, 6, 18),
    idProofType: 'Aadhaar',
    idProofLast4: '7812',
    chits: [
      Chit(
        chitCode: 'THD-1049',
        loanAmount: 15000,
        installmentAmount: 200,
        frequency: ChitFrequency.daily,
        totalInstallments: 75,
        startDate: DateTime(2026, 8, 3),
        installmentsPaid: 40,
        schedule: _buildSchedule(
          start: DateTime(2026, 8, 3),
          freq: ChitFrequency.daily,
          total: 75,
          amount: 200,
          paid: 40,
          overdueCount: 1,
        ),
      ),
    ],
  ));

  customers.add(Customer(
    customerCode: 'THD-10466',
    name: 'Kavitha M',
    phone: '+91 99521 66084',
    address: '31, Garden Street',
    customerSince: DateTime(2026, 9, 12),
    idProofType: 'Voter ID',
    idProofLast4: '4730',
    chits: [
      Chit(
        chitCode: 'THD-1071',
        loanAmount: 10000,
        installmentAmount: 120,
        frequency: ChitFrequency.daily,
        totalInstallments: 100,
        startDate: DateTime(2026, 9, 17),
        installmentsPaid: 2,
        schedule: _buildSchedule(
          start: DateTime(2026, 9, 17),
          freq: ChitFrequency.daily,
          total: 100,
          amount: 120,
          paid: 2,
          overdueCount: 0,
        ),
      ),
    ],
  ));

  customers.add(Customer(
    customerCode: 'THD-10276',
    name: 'Lakshmi Narayanan',
    phone: '+91 90876 44321',
    address: '9, Kamaraj Road',
    customerSince: DateTime(2026, 5, 21),
    idProofType: 'Aadhaar',
    idProofLast4: '2290',
    chits: [
      Chit(
        chitCode: 'THD-1027',
        loanAmount: 8000,
        installmentAmount: 100,
        frequency: ChitFrequency.daily,
        totalInstallments: 80,
        startDate: DateTime(2026, 7, 5),
        installmentsPaid: 55,
        schedule: _buildSchedule(
          start: DateTime(2026, 7, 5),
          freq: ChitFrequency.daily,
          total: 80,
          amount: 100,
          paid: 55,
        ),
      ),
    ],
  ));

  customers.add(Customer(
    customerCode: 'THD-10333',
    name: 'Murugan S',
    phone: '+91 93450 22110',
    address: '2, Market Street',
    customerSince: DateTime(2026, 4, 14),
    idProofType: 'PAN',
    idProofLast4: '119F',
    chits: [
      Chit(
        chitCode: 'THD-1039',
        loanAmount: 18000,
        installmentAmount: 300,
        frequency: ChitFrequency.daily,
        totalInstallments: 60,
        startDate: DateTime(2026, 8, 10),
        installmentsPaid: 27,
        schedule: _buildSchedule(
          start: DateTime(2026, 8, 10),
          freq: ChitFrequency.daily,
          total: 60,
          amount: 300,
          paid: 27,
        ),
      ),
    ],
  ));

  customers.add(Customer(
    customerCode: 'THD-10388',
    name: 'Priya D',
    phone: '+91 91234 55009',
    address: '18, Lake View Road',
    customerSince: DateTime(2026, 3, 2),
    idProofType: 'Voter ID',
    idProofLast4: '5521',
    chits: [
      Chit(
        chitCode: 'THD-1117',
        loanAmount: 30000,
        installmentAmount: 1500,
        frequency: ChitFrequency.weekly,
        totalInstallments: 22,
        startDate: DateTime(2026, 4, 1),
        installmentsPaid: 19,
        schedule: _buildSchedule(
          start: DateTime(2026, 4, 1),
          freq: ChitFrequency.weekly,
          total: 22,
          amount: 1500,
          paid: 19,
          overdueCount: 1,
        ),
      ),
    ],
  ));

  customers.add(Customer(
    customerCode: 'THD-10198',
    name: 'Meena Devi',
    phone: '+91 90031 88221',
    address: '5, North Street',
    customerSince: DateTime(2026, 2, 11),
    idProofType: 'Aadhaar',
    idProofLast4: '3390',
    chits: [
      Chit(
        chitCode: 'THD-1012',
        loanAmount: 20000,
        installmentAmount: 200,
        frequency: ChitFrequency.daily,
        totalInstallments: 100,
        startDate: DateTime(2026, 6, 20),
        installmentsPaid: 70,
        schedule: _buildSchedule(
          start: DateTime(2026, 6, 20),
          freq: ChitFrequency.daily,
          total: 100,
          amount: 200,
          paid: 70,
        ),
      ),
    ],
  ));

  customers.add(Customer(
    customerCode: 'THD-10052',
    name: 'Selvi P',
    phone: '+91 90222 11987',
    address: '44, Station Road',
    customerSince: DateTime(2026, 1, 9),
    idProofType: 'Voter ID',
    idProofLast4: '9981',
    chits: [
      Chit(
        chitCode: 'THD-1052',
        loanAmount: 6000,
        installmentAmount: 120,
        frequency: ChitFrequency.daily,
        totalInstallments: 50,
        startDate: DateTime(2026, 8, 1),
        installmentsPaid: 33,
        schedule: _buildSchedule(
          start: DateTime(2026, 8, 1),
          freq: ChitFrequency.daily,
          total: 50,
          amount: 120,
          paid: 33,
        ),
      ),
    ],
  ));

  customers.add(Customer(
    customerCode: 'THD-10030',
    name: 'Suresh Kumar',
    phone: '+91 90444 22110',
    address: '3, Anna Nagar',
    customerSince: DateTime(2026, 1, 30),
    idProofType: 'Aadhaar',
    idProofLast4: '7743',
    chits: [
      Chit(
        chitCode: 'THD-1030',
        loanAmount: 10000,
        installmentAmount: 200,
        frequency: ChitFrequency.daily,
        totalInstallments: 50,
        startDate: DateTime(2026, 7, 15),
        installmentsPaid: 40,
        schedule: _buildSchedule(
          start: DateTime(2026, 7, 15),
          freq: ChitFrequency.daily,
          total: 50,
          amount: 200,
          paid: 40,
        ),
      ),
    ],
  ));

  customers.add(Customer(
    customerCode: 'THD-10019',
    name: 'Gopal R',
    phone: '+91 90555 66771',
    address: '61, Bazaar Street',
    customerSince: DateTime(2026, 2, 22),
    idProofType: 'Voter ID',
    idProofLast4: '5567',
    chits: [
      Chit(
        chitCode: 'THD-1019',
        loanAmount: 9000,
        installmentAmount: 150,
        frequency: ChitFrequency.daily,
        totalInstallments: 60,
        startDate: DateTime(2026, 7, 1),
        installmentsPaid: 45,
        schedule: _buildSchedule(
          start: DateTime(2026, 7, 1),
          freq: ChitFrequency.daily,
          total: 60,
          amount: 150,
          paid: 45,
        ),
      ),
    ],
  ));

  customers.add(Customer(
    customerCode: 'THD-10009',
    name: 'Fathima Begum',
    phone: '+91 90666 33221',
    address: '8, Mosque Street',
    customerSince: DateTime(2026, 3, 19),
    idProofType: 'Aadhaar',
    idProofLast4: '2201',
    chits: [
      Chit(
        chitCode: 'THD-1009',
        loanAmount: 9000,
        installmentAmount: 180,
        frequency: ChitFrequency.daily,
        totalInstallments: 50,
        startDate: DateTime(2026, 6, 5),
        installmentsPaid: 44,
        schedule: _buildSchedule(
          start: DateTime(2026, 6, 5),
          freq: ChitFrequency.daily,
          total: 50,
          amount: 180,
          paid: 44,
        ),
      ),
    ],
  ));

  return customers;
}

/// Historical (already collected) payments, seeded for the History screen.
List<Payment> buildMockHistory(List<Customer> customers) {
  Customer byCode(String code) => customers.firstWhere((c) => c.customerCode == code);

  final entries = <Payment>[
    Payment(
      receiptNo: 'THD-RCP-000247',
      customer: byCode('THD-10052'),
      chit: byCode('THD-10052').chits.first,
      amount: 120,
      dateTime: DateTime(2026, 9, 19, 10, 31),
      mode: 'Cash',
      collectedBy: 'Karthik R',
    ),
    Payment(
      receiptNo: 'THD-RCP-000246',
      customer: byCode('THD-10030'),
      chit: byCode('THD-10030').chits.first,
      amount: 200,
      dateTime: DateTime(2026, 9, 19, 10, 20),
      mode: 'Cash',
      collectedBy: 'Karthik R',
    ),
    Payment(
      receiptNo: 'THD-RCP-000245',
      customer: byCode('THD-10019'),
      chit: byCode('THD-10019').chits.first,
      amount: 150,
      dateTime: DateTime(2026, 9, 19, 10, 5),
      mode: 'Cash',
      collectedBy: 'Karthik R',
    ),
    Payment(
      receiptNo: 'THD-RCP-000244',
      customer: byCode('THD-10009'),
      chit: byCode('THD-10009').chits.first,
      amount: 180,
      dateTime: DateTime(2026, 9, 19, 9, 40),
      mode: 'Cash',
      collectedBy: 'Karthik R',
    ),
    Payment(
      receiptNo: 'THD-RCP-000231',
      customer: byCode('THD-10198'),
      chit: byCode('THD-10198').chits.first,
      amount: 200,
      dateTime: DateTime(2026, 9, 19, 9, 12),
      mode: 'Cash',
      collectedBy: 'Karthik R · AGT-007',
      correctionStatus: 'pending',
    ),
    Payment(
      receiptNo: 'THD-RCP-000198',
      customer: byCode('THD-10030'),
      chit: byCode('THD-10030').chits.first,
      amount: 200,
      dateTime: DateTime(2026, 9, 18, 11, 40),
      mode: 'Cash',
      collectedBy: 'Karthik R',
    ),
    Payment(
      receiptNo: 'THD-RCP-000197',
      customer: byCode('THD-10333'),
      chit: byCode('THD-10333').chits.first,
      amount: 300,
      dateTime: DateTime(2026, 9, 18, 11, 20),
      mode: 'Cash',
      collectedBy: 'Karthik R',
      correctionStatus: 'approved',
    ),
    Payment(
      receiptNo: 'THD-RCP-000196',
      customer: byCode('THD-10276'),
      chit: byCode('THD-10276').chits.first,
      amount: 100,
      dateTime: DateTime(2026, 9, 18, 10, 50),
      mode: 'Cash',
      collectedBy: 'Karthik R',
    ),
    Payment(
      receiptNo: 'THD-RCP-000195',
      customer: byCode('THD-10030'),
      chit: byCode('THD-10030').chits.first,
      amount: 200,
      dateTime: DateTime(2026, 9, 18, 10, 15),
      mode: 'Cash',
      collectedBy: 'Karthik R',
    ),
    Payment(
      receiptNo: 'THD-RCP-000194',
      customer: byCode('THD-10019'),
      chit: byCode('THD-10019').chits.first,
      amount: 150,
      dateTime: DateTime(2026, 9, 18, 9, 55),
      mode: 'Cash',
      collectedBy: 'Karthik R',
    ),
  ];
  return entries;
}
