@IsTest
private class LeadFollowUpBatchTest {
  @TestSetup
  static void setup() {
    List<Lead> leads = new List<Lead>{
      new Lead(LastName = 'Old', Company = 'Acme'),
      new Lead(LastName = 'Recent', Company = 'Acme'),
      new Lead(
        LastName = 'OldClosed',
        Company = 'Acme',
        Status = 'Closed - Not Converted'
      )
    };
    insert leads;
    Datetime old = Datetime.now().addDays(-61);
    Test.setCreatedDate(leads[0].Id, old);
    Test.setCreatedDate(leads[2].Id, old);
  }

  @IsTest
  static void createsTaskOnlyForOldOpenLeads() {
    Test.startTest();
    Database.executeBatch(new LeadFollowUpBatch());
    Test.stopTest();

    Lead oldLead = [SELECT Id, OwnerId FROM Lead WHERE LastName = 'Old'];
    List<Task> tasks = [
      SELECT OwnerId, ActivityDate, Subject, WhoId
      FROM Task
      WHERE Subject = :LeadFollowUpBatch.TASK_SUBJECT
    ];
    System.assertEquals(
      1,
      tasks.size(),
      'Only the old open lead should get a task'
    );
    System.assertEquals(oldLead.Id, tasks[0].WhoId);
    System.assertEquals(oldLead.OwnerId, tasks[0].OwnerId);
    System.assertEquals(Date.today().addDays(2), tasks[0].ActivityDate);
  }

  @IsTest
  static void doesNotCreateDuplicateTasks() {
    Test.startTest();
    Database.executeBatch(new LeadFollowUpBatch());
    Test.stopTest();

    // Simulate a re-run over the same lead: no second task should be created
    List<Lead> leads = [SELECT Id, OwnerId FROM Lead WHERE LastName = 'Old'];
    new LeadFollowUpBatch().execute(null, leads);

    System.assertEquals(
      1,
      [SELECT COUNT() FROM Task WHERE Subject = :LeadFollowUpBatch.TASK_SUBJECT]
    );
  }
}
