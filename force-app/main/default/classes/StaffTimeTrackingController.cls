public without sharing class StaffTimeTrackingController {

    public class MonthlySummary {
        @AuraEnabled public Decimal totalHours { get; set; }
        @AuraEnabled public Decimal regularHours { get; set; }
        @AuraEnabled public Decimal overtime125Hours { get; set; }
        @AuraEnabled public Decimal overtime150Hours { get; set; }
        @AuraEnabled public Decimal estimatedSalary { get; set; }
        @AuraEnabled public Decimal totalTravel { get; set; }
        @AuraEnabled public Decimal totalBonuses { get; set; }
        @AuraEnabled public Decimal totalExpenses { get; set; }
        @AuraEnabled public Integer workDaysCount { get; set; }
        @AuraEnabled public List<Time_Entry__c> entries { get; set; }
        @AuraEnabled public Employee__c employeeSettings { get; set; }
        
        public MonthlySummary() {
            totalHours = 0;
            regularHours = 0;
            overtime125Hours = 0;
            overtime150Hours = 0;
            estimatedSalary = 0;
            totalTravel = 0;
            totalBonuses = 0;
            totalExpenses = 0;
            workDaysCount = 0;
            entries = new List<Time_Entry__c>();
        }
    }

    // Default Shabbat entry times by month (Tel Aviv / Israel standard)
    private static final Map<Integer, String> SHABBAT_ENTRY_TIMES = new Map<Integer, String>{
        1 => '16:40',
        2 => '17:05',
        3 => '17:30',
        4 => '18:50',
        5 => '19:15',
        6 => '19:30',
        7 => '19:30',
        8 => '19:05',
        9 => '18:25',
        10 => '17:45',
        11 => '16:20',
        12 => '16:20'
    };

    // Official Israeli Holidays and Eves of Holidays
    private static final Set<String> FULL_HOLIDAYS = new Set<String>{
        '2026-04-02', '2026-04-08', '2026-04-22', '2026-05-22',
        '2026-09-12', '2026-09-13', '2026-09-26', '2026-10-02',
        '2025-04-13', '2025-04-19', '2025-06-02', '2025-09-23', '2025-09-24', '2025-10-07', '2025-10-14'
    };

    private static final Set<String> EVE_OF_HOLIDAYS = new Set<String>{
        '2026-04-01', '2026-04-07', '2026-04-21', '2026-05-21',
        '2026-09-11', '2026-09-25', '2026-10-01',
        '2025-04-12', '2025-04-18', '2025-06-01', '2025-09-22', '2025-10-06', '2025-10-13'
    };

    @AuraEnabled(cacheable=false)
    public static MonthlySummary getMonthlyReport(Id employeeId, Integer year, Integer month) {
        MonthlySummary summary = new MonthlySummary();
        if (employeeId == null) return summary;

        // 1. Fetch Employee settings
        List<Employee__c> emps = [
            SELECT Id, Name, Employee_Type__c, Monthly_Salary__c, Travel_Cost__c, Full_Day_Rate__c, Course_Rate__c,
                   Job_Percentage__c, Rate_Instruction__c, Rate_Club__c, Rate_Skipper__c, Rate_Maintenance__c,
                   Rate_Dock_Duty__c, Rate_General__c
            FROM Employee__c
            WHERE Id = :employeeId
            LIMIT 1
        ];
        if (emps.isEmpty()) return summary;
        Employee__c emp = emps[0];
        summary.employeeSettings = emp;

        // Apply defaults if null
        if (emp.Travel_Cost__c == null) emp.Travel_Cost__c = 25;
        if (emp.Full_Day_Rate__c == null) emp.Full_Day_Rate__c = 590;
        if (emp.Course_Rate__c == null) emp.Course_Rate__c = 700;
        if (emp.Rate_Instruction__c == null) emp.Rate_Instruction__c = 70;
        if (emp.Rate_Club__c == null) emp.Rate_Club__c = 70;
        if (emp.Rate_Skipper__c == null) emp.Rate_Skipper__c = 70;
        if (emp.Rate_Maintenance__c == null) emp.Rate_Maintenance__c = 50;
        if (emp.Rate_Dock_Duty__c == null) emp.Rate_Dock_Duty__c = 50;
        if (emp.Rate_General__c == null) emp.Rate_General__c = 70;
        if (emp.Monthly_Salary__c == null) emp.Monthly_Salary__c = 0;

        // 2. Date boundaries
        Date monthStart = Date.newInstance(year, month, 1);
        Date monthEnd = monthStart.addMonths(1).addDays(-1);
        DateTime startDateTime = DateTime.newInstance(monthStart, Time.newInstance(0, 0, 0, 0));
        DateTime endDateTime = DateTime.newInstance(monthEnd.addDays(1), Time.newInstance(0, 0, 0, 0));

        // 3. Query existing Time_Entry__c records
        List<Time_Entry__c> existingEntries = [
            SELECT Id, Name, Employee__c, Cruise__c, Work_Date__c, Start_Time__c, End_Time__c,
                   Total_Hours__c, Regular_Hours__c, Overtime_125_Hours__c, Overtime_150_Hours__c,
                   Entry_Type__c, Base_Rate__c, Multiplier__c, Total_Payment__c, Description__c,
                   Status__c, Is_Auto_Generated__c, Is_Manual_Edit__c
            FROM Time_Entry__c
            WHERE Employee__c = :employeeId
              AND Work_Date__c >= :monthStart
              AND Work_Date__c <= :monthEnd
        ];

        Set<Id> existingCruiseIds = new Set<Id>();
        for (Time_Entry__c te : existingEntries) {
            if (te.Cruise__c != null) {
                existingCruiseIds.add(te.Cruise__c);
            }
        }

        // 4. Query assigned non-canceled cruises for this employee
        List<Cruise__c> cruises = [
            SELECT Id, Name, Start_Date__c, End_Date__c, Status__c, Dock_Duty__c,
                   RecordType.Name, RecordType.DeveloperName, Boat__r.Name
            FROM Cruise__c
            WHERE Guide__c = :employeeId
              AND Start_Date__c >= :startDateTime
              AND Start_Date__c < :endDateTime
              AND Status__c != 'Canceled'
            ORDER BY Start_Date__c ASC
        ];

        // 5. Auto-generate Time_Entry__c for cruises not yet tracked
        List<Time_Entry__c> newCruiseEntries = new List<Time_Entry__c>();
        for (Cruise__c c : cruises) {
            if (!existingCruiseIds.contains(c.Id)) {
                Time_Entry__c te = createEntryFromCruise(c, emp, month);
                newCruiseEntries.add(te);
            }
        }

        if (!newCruiseEntries.isEmpty()) {
            insert newCruiseEntries;
        }

        // 6. Query all entries for the month sorted chronologically
        List<Time_Entry__c> allEntries = [
            SELECT Id, Name, Employee__c, Cruise__c, Work_Date__c, Start_Time__c, End_Time__c,
                   Total_Hours__c, Regular_Hours__c, Overtime_125_Hours__c, Overtime_150_Hours__c,
                   Entry_Type__c, Base_Rate__c, Multiplier__c, Total_Payment__c, Description__c,
                   Status__c, Is_Auto_Generated__c, Is_Manual_Edit__c
            FROM Time_Entry__c
            WHERE Employee__c = :employeeId
              AND Work_Date__c >= :monthStart
              AND Work_Date__c <= :monthEnd
            ORDER BY Work_Date__c ASC, Start_Time__c ASC
        ];
        summary.entries = allEntries;

        // 7. Calculate aggregate summary
        Set<Date> uniqueWorkDays = new Set<Date>();
        Decimal totalWage = 0;

        for (Time_Entry__c te : allEntries) {
            if (te.Status__c == 'נדחה') continue;

            if (te.Total_Hours__c != null) summary.totalHours += te.Total_Hours__c;
            if (te.Regular_Hours__c != null) summary.regularHours += te.Regular_Hours__c;
            if (te.Overtime_125_Hours__c != null) summary.overtime125Hours += te.Overtime_125_Hours__c;
            if (te.Overtime_150_Hours__c != null) summary.overtime150Hours += te.Overtime_150_Hours__c;

            if (te.Entry_Type__c == 'בונוס' && te.Total_Payment__c != null) {
                summary.totalBonuses += te.Total_Payment__c;
            } else if (te.Entry_Type__c == 'החזר הוצאות' && te.Total_Payment__c != null) {
                summary.totalExpenses += te.Total_Payment__c;
            } else {
                if (te.Total_Payment__c != null) totalWage += te.Total_Payment__c;
                if (te.Work_Date__c != null && te.Total_Hours__c != null && te.Total_Hours__c > 0) {
                    uniqueWorkDays.add(te.Work_Date__c);
                }
            }
        }

        summary.workDaysCount = uniqueWorkDays.size();
        summary.totalTravel = summary.workDaysCount * emp.Travel_Cost__c;

        if (emp.Employee_Type__c == 'חודשי' && emp.Monthly_Salary__c > 0) {
            summary.estimatedSalary = emp.Monthly_Salary__c + summary.totalTravel + summary.totalBonuses + summary.totalExpenses;
        } else {
            summary.estimatedSalary = totalWage + summary.totalTravel + summary.totalBonuses + summary.totalExpenses;
        }

        return summary;
    }

    private static Time_Entry__c createEntryFromCruise(Cruise__c c, Employee__c emp, Integer month) {
        Time_Entry__c te = new Time_Entry__c();
        te.Employee__c = emp.Id;
        te.Cruise__c = c.Id;
        te.Is_Auto_Generated__c = true;
        te.Is_Manual_Edit__c = false;
        te.Status__c = 'אושר';

        Date workDate = c.Start_Date__c.date();
        te.Work_Date__c = workDate;

        String startTimeStr = c.Start_Date__c.format('HH:mm');
        String endTimeStr = c.End_Date__c.format('HH:mm');
        te.Start_Time__c = startTimeStr;
        te.End_Time__c = endTimeStr;

        Decimal totalHours = Decimal.valueOf(c.End_Date__c.getTime() - c.Start_Date__c.getTime()) / (1000.0 * 60 * 60);
        totalHours = totalHours.setScale(2, RoundingMode.HALF_UP);
        te.Total_Hours__c = totalHours;

        // Determine Entry Type and Base Rate
        String devName = c.RecordType != null ? c.RecordType.DeveloperName : '';
        Decimal baseRate = emp.Rate_Instruction__c != null ? emp.Rate_Instruction__c : 70;
        String entryType = 'הפלגה';

        if (c.Dock_Duty__c == true) {
            entryType = 'תורנות רציף';
            baseRate = emp.Rate_Dock_Duty__c != null ? emp.Rate_Dock_Duty__c : 50;
        } else if (devName == 'Renting') {
            // השכרה / צ'רטר -> השכרת יאכטות (צ'רטר)
            entryType = 'הפלגה';
            baseRate = emp.Rate_Skipper__c != null ? emp.Rate_Skipper__c : (emp.Rate_Instruction__c != null ? emp.Rate_Instruction__c : 70);
        } else if (devName == 'Maintenance') {
            entryType = 'תחזוקה';
            baseRate = emp.Rate_Maintenance__c != null ? emp.Rate_Maintenance__c : 50;
        } else if (devName == 'Course' || devName == 'Club' || devName == 'Introduction' || devName == 'Enriching' || devName == 'Friends' || devName == 'Certification') {
            // מודרכת, קורס, הכרות, מועדון, העשרה -> הדרכה בים
            entryType = (devName == 'Course') ? 'קורס' : 'הפלגה';
            baseRate = emp.Rate_Instruction__c != null ? emp.Rate_Instruction__c : 70;
        } else {
            // כל סוג אחר של הפלגה -> ברירת מחדל הדרכה בים (או כללי אם הוגדר)
            entryType = 'הפלגה';
            baseRate = emp.Rate_Instruction__c != null ? emp.Rate_Instruction__c : (emp.Rate_General__c != null ? emp.Rate_General__c : 70);
        }

        te.Entry_Type__c = entryType;
        te.Base_Rate__c = baseRate;
        te.Description__c = (c.Boat__r != null ? c.Boat__r.Name + ' - ' : '') + (c.RecordType != null ? c.RecordType.Name : '');

        // Calculate Multiplier and Payment based on day of week & Israeli Holidays
        Date sundayRef = Date.newInstance(1900, 1, 7); // A known Sunday
        Integer dayOfWeek = Math.mod(sundayRef.daysBetween(workDate), 7); // 0 = Sunday, 1 = Monday, ..., 5 = Friday, 6 = Saturday

        String dateStr = DateTime.newInstance(workDate, Time.newInstance(0, 0, 0, 0)).format('yyyy-MM-dd');
        Boolean isFullHoliday = FULL_HOLIDAYS.contains(dateStr);
        Boolean isEveOfHoliday = EVE_OF_HOLIDAYS.contains(dateStr);

        Decimal multiplier = 1.0;
        Decimal regHours = 0;
        Decimal ot125 = 0;
        Decimal ot150 = 0;
        Decimal payment = 0;

        if (isFullHoliday || dayOfWeek == 6) {
            // Saturday or Full Official Holiday — 150% holiday multiplier
            multiplier = 1.5;
            ot150 = totalHours;
            payment = totalHours * baseRate * 1.5;
        } else if (isEveOfHoliday || dayOfWeek == 5) {
            // Friday or Eve of Holiday — check Shabbat / Holiday entry time
            String entryTimeStr = SHABBAT_ENTRY_TIMES.get(month);
            if (entryTimeStr == null) entryTimeStr = '18:00';

            List<String> entryParts = entryTimeStr.split(':');
            Integer entryHour = Integer.valueOf(entryParts[0]);
            Integer entryMin = Integer.valueOf(entryParts[1]);

            Integer startHour = c.Start_Date__c.hour();
            Integer startMin = c.Start_Date__c.minute();
            Integer endHour = c.End_Date__c.hour();
            Integer endMin = c.End_Date__c.minute();

            Decimal startDec = startHour + (startMin / 60.0);
            Decimal endDec = endHour + (endMin / 60.0);
            Decimal entryDec = entryHour + (entryMin / 60.0);

            if (endDec <= entryDec) {
                // Completely before Shabbat / Holiday entry
                regHours = totalHours;
                multiplier = 1.0;
                payment = totalHours * baseRate;
            } else if (startDec >= entryDec) {
                // Completely after Shabbat / Holiday entry (150%)
                ot150 = totalHours;
                multiplier = 1.5;
                payment = totalHours * baseRate * 1.5;
            } else {
                // Spans across Shabbat / Holiday entry
                Decimal beforeHours = (entryDec - startDec).setScale(2, RoundingMode.HALF_UP);
                Decimal afterHours = (endDec - entryDec).setScale(2, RoundingMode.HALF_UP);
                regHours = beforeHours;
                ot150 = afterHours;
                payment = (beforeHours * baseRate) + (afterHours * baseRate * 1.5);
                multiplier = totalHours > 0 ? (payment / (totalHours * baseRate)) : 1.0;
            }
        } else {
            // Sunday through Thursday (regular day)
            if (totalHours <= 8) {
                regHours = totalHours;
                multiplier = 1.0;
                payment = totalHours * baseRate;
            } else if (totalHours <= 10) {
                regHours = 8;
                ot125 = totalHours - 8;
                multiplier = 1.05;
                payment = (8 * baseRate) + (ot125 * baseRate * 1.25);
            } else {
                regHours = 8;
                ot125 = 2;
                ot150 = totalHours - 10;
                payment = (8 * baseRate) + (2 * baseRate * 1.25) + (ot150 * baseRate * 1.5);
                multiplier = totalHours > 0 ? (payment / (totalHours * baseRate)) : 1.0;
            }
        }

        te.Regular_Hours__c = regHours;
        te.Overtime_125_Hours__c = ot125;
        te.Overtime_150_Hours__c = ot150;
        te.Multiplier__c = multiplier.setScale(2, RoundingMode.HALF_UP);
        te.Total_Payment__c = payment.setScale(2, RoundingMode.HALF_UP);

        return te;
    }

    @AuraEnabled
    public static Time_Entry__c saveTimeEntry(Time_Entry__c entry) {
        if (entry == null) throw new AuraHandledException('Entry cannot be null');

        // Fetch Employee rates if base rate is 0
        if (entry.Base_Rate__c == null || entry.Base_Rate__c == 0) {
            Employee__c emp = [
                SELECT Id, Full_Day_Rate__c, Course_Rate__c, Rate_Instruction__c, Rate_Club__c,
                       Rate_Skipper__c, Rate_Maintenance__c, Rate_Dock_Duty__c, Rate_General__c
                FROM Employee__c
                WHERE Id = :entry.Employee__c
                LIMIT 1
            ];

            if (entry.Entry_Type__c == 'תורנות רציף') entry.Base_Rate__c = emp.Rate_Dock_Duty__c != null ? emp.Rate_Dock_Duty__c : 50;
            else if (entry.Entry_Type__c == 'תחזוקה') entry.Base_Rate__c = emp.Rate_Maintenance__c != null ? emp.Rate_Maintenance__c : 50;
            else if (entry.Entry_Type__c == 'חו״ל / יום מלא') entry.Base_Rate__c = emp.Full_Day_Rate__c != null ? emp.Full_Day_Rate__c : 590;
            else if (entry.Entry_Type__c == 'קורס') entry.Base_Rate__c = emp.Course_Rate__c != null ? emp.Course_Rate__c : 700;
            else entry.Base_Rate__c = emp.Rate_General__c != null ? emp.Rate_General__c : 70;
        }

        // If hours provided, recalculate Total_Hours and Payment
        if (entry.Start_Time__c != null && entry.End_Time__c != null && entry.Start_Time__c.contains(':') && entry.End_Time__c.contains(':')) {
            List<String> startParts = entry.Start_Time__c.split(':');
            List<String> endParts = entry.End_Time__c.split(':');
            Decimal startDec = Integer.valueOf(startParts[0]) + (Integer.valueOf(startParts[1]) / 60.0);
            Decimal endDec = Integer.valueOf(endParts[0]) + (Integer.valueOf(endParts[1]) / 60.0);

            if (endDec > startDec) {
                entry.Total_Hours__c = (endDec - startDec).setScale(2, RoundingMode.HALF_UP);
                if (entry.Multiplier__c == null || entry.Multiplier__c == 0) entry.Multiplier__c = 1.0;
                entry.Total_Payment__c = (entry.Total_Hours__c * entry.Base_Rate__c * entry.Multiplier__c).setScale(2, RoundingMode.HALF_UP);
            }
        } else if (entry.Entry_Type__c == 'חו״ל / יום מלא' || entry.Entry_Type__c == 'קורס') {
            if (entry.Total_Payment__c == null || entry.Total_Payment__c == 0) {
                entry.Total_Payment__c = entry.Base_Rate__c;
            }
        }

        upsert entry;
        return entry;
    }

    @AuraEnabled
    public static Boolean deleteTimeEntry(Id entryId) {
        if (entryId == null) return false;
        List<Time_Entry__c> toDelete = [SELECT Id FROM Time_Entry__c WHERE Id = :entryId LIMIT 1];
        if (!toDelete.isEmpty()) {
            delete toDelete;
            return true;
        }
        return false;
    }

    public class AccountantReportRow {
        @AuraEnabled public String employeeId { get; set; }
        @AuraEnabled public String employeeName { get; set; }
        @AuraEnabled public String jobType { get; set; }
        @AuraEnabled public Integer workDays { get; set; }
        @AuraEnabled public Decimal totalHours { get; set; }
        @AuraEnabled public Decimal grossPayment { get; set; }
        @AuraEnabled public Decimal bonuses { get; set; }
        @AuraEnabled public String bonusReasons { get; set; }
        @AuraEnabled public Decimal travelPayment { get; set; }
        @AuraEnabled public Decimal expenseReimbursement { get; set; }
        @AuraEnabled public Decimal sickDays { get; set; }
        @AuraEnabled public Decimal vacationDays { get; set; }
        @AuraEnabled public Decimal finalPayment { get; set; }

        public AccountantReportRow() {
            workDays = 0;
            totalHours = 0;
            grossPayment = 0;
            bonuses = 0;
            bonusReasons = '';
            travelPayment = 0;
            expenseReimbursement = 0;
            sickDays = 0;
            vacationDays = 0;
            finalPayment = 0;
        }
    }

    @AuraEnabled(cacheable=false)
    public static List<AccountantReportRow> getAccountantMonthlyReport(Integer year, Integer month) {
        List<AccountantReportRow> rows = new List<AccountantReportRow>();

        // 1. Fetch all employees
        List<Employee__c> emps = [
            SELECT Id, Name, Employee_Type__c, Monthly_Salary__c, Job_Percentage__c, Travel_Cost__c,
                   Full_Day_Rate__c, Course_Rate__c, Rate_Instruction__c, Rate_Club__c, Rate_Skipper__c,
                   Rate_Maintenance__c, Rate_Dock_Duty__c, Rate_General__c
            FROM Employee__c
            ORDER BY Name ASC
        ];
        if (emps.isEmpty()) return rows;

        Date monthStart = Date.newInstance(year, month, 1);
        Date monthEnd = monthStart.addMonths(1).addDays(-1);
        DateTime startDateTime = DateTime.newInstance(monthStart, Time.newInstance(0, 0, 0, 0));
        DateTime endDateTime = DateTime.newInstance(monthEnd.addDays(1), Time.newInstance(0, 0, 0, 0));

        // 2. Fetch all Time_Entry__c for the month (Query 2)
        List<Time_Entry__c> allEntries = [
            SELECT Id, Employee__c, Cruise__c, Work_Date__c, Total_Hours__c, Entry_Type__c, Total_Payment__c, Description__c, Status__c
            FROM Time_Entry__c
            WHERE Work_Date__c >= :monthStart
              AND Work_Date__c <= :monthEnd
              AND Status__c != 'נדחה'
        ];

        Map<Id, List<Time_Entry__c>> entriesByEmp = new Map<Id, List<Time_Entry__c>>();
        Set<Id> cruisesWithEntries = new Set<Id>();
        for (Time_Entry__c te : allEntries) {
            if (!entriesByEmp.containsKey(te.Employee__c)) {
                entriesByEmp.put(te.Employee__c, new List<Time_Entry__c>());
            }
            entriesByEmp.get(te.Employee__c).add(te);
            if (te.Cruise__c != null) cruisesWithEntries.add(te.Cruise__c);
        }

        // 3. Pre-fetch all non-canceled cruises in the month in ONE query (Query 3)
        List<Cruise__c> monthCruises = [
            SELECT Id, Name, Guide__c, Start_Date__c, End_Date__c, Status__c,
                   RecordType.Name, RecordType.DeveloperName, Boat__r.Name, Dock_Duty__c
            FROM Cruise__c
            WHERE Start_Date__c >= :startDateTime
              AND Start_Date__c < :endDateTime
              AND Status__c != 'Canceled'
              AND Guide__c != null
        ];

        Map<Id, List<Cruise__c>> cruisesByEmp = new Map<Id, List<Cruise__c>>();
        for (Cruise__c c : monthCruises) {
            if (!cruisesWithEntries.contains(c.Id)) {
                if (!cruisesByEmp.containsKey(c.Guide__c)) {
                    cruisesByEmp.put(c.Guide__c, new List<Cruise__c>());
                }
                cruisesByEmp.get(c.Guide__c).add(c);
            }
        }

        // 4. Process each employee (In-Memory!)
        for (Employee__c emp : emps) {
            List<Time_Entry__c> empEntries = entriesByEmp.get(emp.Id);
            if (empEntries == null) empEntries = new List<Time_Entry__c>();

            // Add cruise entries if any were not yet created as Time_Entry__c
            List<Cruise__c> empCruises = cruisesByEmp.get(emp.Id);
            if (empCruises != null && !empCruises.isEmpty()) {
                for (Cruise__c c : empCruises) {
                    empEntries.add(createEntryFromCruise(c, emp, month));
                }
            }

            Boolean isMonthly = emp.Employee_Type__c == 'חודשי';
            if (empEntries.isEmpty() && !isMonthly) {
                continue;
            }

            AccountantReportRow row = new AccountantReportRow();
            row.employeeId = emp.Id;
            row.employeeName = emp.Name;

            String jobTypeStr = isMonthly ? 'משרה מלאה' : 'שעתי';
            if (isMonthly && emp.Job_Percentage__c != null && emp.Job_Percentage__c < 100) {
                jobTypeStr += ' ' + emp.Job_Percentage__c + '%';
            }
            row.jobType = jobTypeStr;

            Set<Date> workDaysSet = new Set<Date>();
            Decimal hoursSum = 0;
            Decimal hourlyPaySum = 0;
            Decimal fullDaysPay = 0;
            Decimal coursesPay = 0;
            Decimal travelAllowance = emp.Travel_Cost__c != null ? emp.Travel_Cost__c : 25;
            List<String> bonusReasonsList = new List<String>();

            for (Time_Entry__c te : empEntries) {
                if (te.Total_Hours__c != null) hoursSum += te.Total_Hours__c;

                if (te.Entry_Type__c == 'בונוס') {
                    if (te.Total_Payment__c != null) row.bonuses += te.Total_Payment__c;
                    if (String.isNotBlank(te.Description__c)) bonusReasonsList.add(te.Description__c);
                } else if (te.Entry_Type__c == 'החזר הוצאות') {
                    if (te.Total_Payment__c != null) row.expenseReimbursement += te.Total_Payment__c;
                } else if (te.Entry_Type__c == 'מחלה') {
                    row.sickDays += (te.Total_Hours__c != null && te.Total_Hours__c > 0 ? (te.Total_Hours__c / 8.0) : 1);
                } else if (te.Entry_Type__c == 'חופשה') {
                    row.vacationDays += (te.Total_Hours__c != null && te.Total_Hours__c > 0 ? (te.Total_Hours__c / 8.0) : 1);
                } else if (te.Entry_Type__c == 'חו״ל / יום מלא') {
                    if (te.Total_Payment__c != null) fullDaysPay += te.Total_Payment__c;
                    if (te.Work_Date__c != null) workDaysSet.add(te.Work_Date__c);
                } else if (te.Entry_Type__c == 'קורס') {
                    if (te.Total_Payment__c != null) coursesPay += te.Total_Payment__c;
                    if (te.Work_Date__c != null) workDaysSet.add(te.Work_Date__c);
                } else {
                    if (te.Total_Payment__c != null) hourlyPaySum += te.Total_Payment__c;
                    if (te.Work_Date__c != null && te.Total_Hours__c != null && te.Total_Hours__c > 0) {
                        workDaysSet.add(te.Work_Date__c);
                    }
                }
            }

            row.workDays = workDaysSet.size();
            row.totalHours = hoursSum.setScale(2, RoundingMode.HALF_UP);
            row.bonusReasons = String.join(bonusReasonsList, ', ');

            if (isMonthly) {
                Decimal baseSal = emp.Monthly_Salary__c != null ? emp.Monthly_Salary__c : 0;
                row.grossPayment = (baseSal + hourlyPaySum + fullDaysPay + coursesPay).setScale(2, RoundingMode.HALF_UP);
                row.travelPayment = 250;
            } else {
                row.grossPayment = (hourlyPaySum + fullDaysPay + coursesPay).setScale(2, RoundingMode.HALF_UP);
                row.travelPayment = (row.workDays * travelAllowance).setScale(2, RoundingMode.HALF_UP);
            }

            row.finalPayment = (row.grossPayment + row.travelPayment + row.bonuses + row.expenseReimbursement).setScale(2, RoundingMode.HALF_UP);
            rows.add(row);
        }

        return rows;
    }
}
