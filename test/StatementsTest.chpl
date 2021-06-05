use UnitTest;
use DatabaseCommunicator.QueryBuilder;

proc statementTestWithNoPlaceholder(test: borrowed Test) throws {
  var st1: Statement = new Statement("SELECT * FROM CONTACTS;");
  test.assertTrue(st1.getSubstitutedStatement() == "SELECT * FROM CONTACTS;");
}

proc shouldReturnSameStatementWhenToSubsIsFalse(test: borrowed Test) throws {
  // toSubstitute, the second argument of Statement.init is false by default
  var st2: Statement = new Statement("SELECT * FROM CONTACTS WHERE id = ?1 AND name = ?2;");
  st2.setValue(1, 0);
  st2.setValue(2, "testuser");
  test.assertTrue(st2.getSubstitutedStatement() == "SELECT * FROM CONTACTS WHERE id = ?1 AND name = ?2;");
}

proc statementSubstitutionNormal(test: borrowed Test) throws {
  var st3: Statement = new Statement("SELECT * FROM CONTACTS WHERE id = ?1 AND name = ?2 AND has_legs = ?3;", true);
  st3.setValue(1, 1);
  st3.setValue(2, "testuser");
  st3.setValue(3, true);
  test.assertFalse(st3._isPlaceholderRemaining());
  test.assertTrue(st3.getSubstitutedStatement() == "SELECT * FROM CONTACTS WHERE id = 1 AND name = 'testuser' AND has_legs = true;");
}

proc statementSubstitutionConstructorSetValue(test: borrowed Test) throws {
  var st35: Statement = new Statement("SELECT * FROM CONTACTS WHERE id = ?1 AND name = ?2 AND has_legs = ?3;", 
                                      true, 1, "testuser", true);
  test.assertFalse(st35._isPlaceholderRemaining());
  test.assertTrue(st35.getSubstitutedStatement() == "SELECT * FROM CONTACTS WHERE id = 1 AND name = 'testuser' AND has_legs = true;");
}

proc statementSubstitutionConstructorMorePlaceholders(test: borrowed Test) throws {
  // Test for the scenario when the statement variadic constructor has less arguments
  // than the maximum placeholder index in the statement

  // TODO: rewrite this test in a better way when the UnitTest library supports testing exceptions.

  // Since this is a halting test, the line that triggers halt is commented:
  // var st35: Statement = new Statement("SELECT * FROM CONTACTS WHERE id = ?1 AND name = ?2 AND has_legs = ?3;", 
  //                                    true, 1, "testuser");
}

proc statementSubstitutionSetValueWrongPlaceholder(test: borrowed Test) throws {
  // calling setValue with wrong placeholder index
  var st355: Statement = new Statement("SELECT * FROM CONTACTS WHERE id = ?1 AND name = ?2 AND has_legs = ?3;", true);
  
  // Note: this test shall halt the program execution, and so the line that halts is commented

  // SHOULD HALT:
  // st355.setValue(4, "badindex");
  // TODO: when we can test exceptions, throw an exception and test it
}

proc statementSubstitutionPlaceholderNoOrder(test: borrowed Test) throws {
  var st3555: Statement = new Statement("SELECT * FROM CONTACTS WHERE id = ?1 AND name = ?2 AND has_legs = ?3;", true);
  st3555.setValue(2, "testuser");
  st3555.setValue(1, 1);
  st3555.setValue(3, true);

  test.assertFalse(st3._isPlaceholderRemaining());
  test.assertTrue(st3.getSubstitutedStatement() == "SELECT * FROM CONTACTS WHERE id = 1 AND name = 'testuser' AND has_legs = true;");
}

proc placeholderRemainingGivesError(test: borrowed Test) throws {
  var st4: Statement = new Statement("SELECT * FROM CONTACTS WHERE id = ?1 AND name = ?2 AND has_legs = ?3;", true);
  st4.setValue(1, 1);
  st4.setValue(3, true);
  writeln("[Note] IncompleteStatementError should be thrown in this test.");
  test.assertTrue(st4._isPlaceholderRemaining());
  test.assertTrue(st4.getSubstitutedStatement() == "SELECT * FROM CONTACTS WHERE id = 1 AND name = ?2 AND has_legs = true;");
}

proc substitutionWorksWithSpaces(test: borrowed Test) throws {
  var st3: Statement = new Statement("SELECT * FROM CONTACTS WHERE id =   ?1 AND name = ?2 AND has_legs = ?3;", true);
  st3.setValue(1, 1);
  st3.setValue(2, "testuser");
  st3.setValue(3, true);
  test.assertFalse(st3._isPlaceholderRemaining());
  test.assertTrue(st3.getSubstitutedStatement() == "SELECT * FROM CONTACTS WHERE id =   1 AND name = 'testuser' AND has_legs = true;");
}

proc placeholderRemainingGivesErrorWithSpaces(test: borrowed Test) throws {
  var st4: Statement = new Statement("SELECT * FROM CONTACTS WHERE id =   ?1 AND name = ?2 AND has_legs = ?3;", true);
  st4.setValue(1, 1);
  st4.setValue(3, true);
  writeln("[Note] IncompleteStatementError should be thrown in this test.");
  test.assertTrue(st4._isPlaceholderRemaining());
  test.assertTrue(st4.getSubstitutedStatement() == "SELECT * FROM CONTACTS WHERE id =   1 AND name = ?2 AND has_legs = true;");
}

UnitTest.main();
