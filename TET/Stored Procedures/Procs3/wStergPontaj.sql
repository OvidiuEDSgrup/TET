--***
Create procedure wStergPontaj @sesiune varchar(50), @parXML xml
as
Begin
	exec wStergPontajEfectiv @sesiune, @parXML, 1
End
