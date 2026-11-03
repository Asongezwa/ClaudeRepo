/**
 * SCRUM-5: Finds Leads that have been open for 60 days or more and creates a
 * follow-up Task for each, assigned to the Lead owner and due in 2 days.
 *
 * Run: Database.executeBatch(new LeadFollowUpBatch(), 200);
 */
public with sharing class LeadFollowUpBatch implements Database.Batchable<SObject> {
  public static final String TASK_SUBJECT = 'Close the Lead or mark it bogus';
  public static final Integer DAYS_OPEN = 60;
  public static final Integer DAYS_UNTIL_DUE = 2;

  public Database.QueryLocator start(Database.BatchableContext bc) {
    Datetime cutoff = Datetime.now().addDays(-DAYS_OPEN);
    return Database.getQueryLocator(
      [
        SELECT Id, OwnerId
        FROM Lead
        WHERE
          IsConverted = FALSE
          AND Status != 'Closed - Not Converted'
          AND CreatedDate <= :cutoff
      ]
    );
  }

  public void execute(Database.BatchableContext bc, List<Lead> leads) {
    // Skip Leads that already have an open follow-up task (avoids duplicates on re-runs)
    Set<Id> leadsWithTask = new Set<Id>();
    for (Task t : [
      SELECT WhoId
      FROM Task
      WHERE WhoId IN :leads AND Subject = :TASK_SUBJECT AND IsClosed = FALSE
    ]) {
      leadsWithTask.add(t.WhoId);
    }

    List<Task> tasks = new List<Task>();
    for (Lead l : leads) {
      // Tasks cannot be owned by queues
      if (
        leadsWithTask.contains(l.Id) ||
        String.valueOf(l.OwnerId).startsWith('00G')
      ) {
        continue;
      }
      tasks.add(
        new Task(
          Subject = TASK_SUBJECT,
          WhoId = l.Id,
          OwnerId = l.OwnerId,
          ActivityDate = Date.today().addDays(DAYS_UNTIL_DUE),
          Status = 'Not Started'
        )
      );
    }
    if (!tasks.isEmpty()) {
      insert tasks;
    }
  }

  public void finish(Database.BatchableContext bc) {
  }
}
