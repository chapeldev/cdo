use UnitTest;
use DatabaseCommunicator.DatabaseCommunicationObjects.QueryBuilder;

proc statementTest1(test: borrowed Test) throws {
    var st1: Statement = new Statement("SELECT * FROM CONTACTS;");
    test.assertTrue(st1.getSubstitutedStatement() == "SELECT * FROM CONTACTS;");
}

proc statementTest2(test: borrowed Test) throws {
    var st2: Statement = new Statement("SELECT * FROM CONTACTS WHERE id = ?1 AND name = ?2;");
    st2.setValue(1, 0);
    st2.setValue(2, "testuser");
    test.assertTrue(st2.getSubstitutedStatement() == "SELECT * FROM CONTACTS WHERE id = ?1 AND name = ?2;");
}

proc statementTest3(test: borrowed Test) throws {
    var st3: Statement = new Statement("SELECT * FROM CONTACTS WHERE id = ?1 AND name = ?2 AND has_legs = ?3;", true);
    st3.setValue(1, 1);
    st3.setValue(2, "testuser");
    st3.setValue(3, true);
    test.assertFalse(st3.isPlaceholderRemaining());
    test.assertTrue(st3.getSubstitutedStatement() == "SELECT * FROM CONTACTS WHERE id = 1 AND name = 'testuser' AND has_legs = true;");
}

proc statementTest4(test: borrowed Test) throws {
    var st4: Statement = new Statement("SELECT * FROM CONTACTS WHERE id = ?1 AND name = ?2 AND has_legs = ?3;", true);
    st4.setValue(1, 1);
    st4.setValue(3, true);
    writeln("[Note] IncompleteStatementError should be thrown in this test.");
    test.assertTrue(st4.isPlaceholderRemaining());
    test.assertTrue(st4.getSubstitutedStatement() == "SELECT * FROM CONTACTS WHERE id = 1 AND name = ?2 AND has_legs = true;");
}

proc statementTest5(test: borrowed Test) throws {
    var st3: Statement = new Statement("SELECT * FROM CONTACTS WHERE id =   ?1 AND name = ?2 AND has_legs = ?3;", true);
    st3.setValue(1, 1);
    st3.setValue(2, "testuser");
    st3.setValue(3, true);
    test.assertFalse(st3.isPlaceholderRemaining());
    test.assertTrue(st3.getSubstitutedStatement() == "SELECT * FROM CONTACTS WHERE id =   1 AND name = 'testuser' AND has_legs = true;");
}

proc statementTest6(test: borrowed Test) throws {
    var st4: Statement = new Statement("SELECT * FROM CONTACTS WHERE id =   ?1 AND name = ?2 AND has_legs = ?3;", true);
    st4.setValue(1, 1);
    st4.setValue(3, true);
    writeln("[Note] IncompleteStatementError should be thrown in this test.");
    test.assertTrue(st4.isPlaceholderRemaining());
    test.assertTrue(st4.getSubstitutedStatement() == "SELECT * FROM CONTACTS WHERE id =   1 AND name = ?2 AND has_legs = true;");
}

UnitTest.main();