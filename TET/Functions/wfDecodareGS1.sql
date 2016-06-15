
CREATE FUNCTION wfDecodareGS1(@cod varchar(1000)) returns @decod table(coloana varchar(200),coloana_asis varchar(200), valoare varchar(200))
as
begin	
	/*
		Exemple:
		(00)093122340000008617
		(01)08340712344613(400)SO-100472(10)100-22


	select * from dbo.wfDecodareGS1('(01)08340712344613(400)SO-100472(10)100-22')
	select * from dbo.wfDecodareGS1('(00)093122340000008617')
	select * from dbo.wfDecodareGS1('(00)001(01)00038(10)11000003')
		
	*/
	INSERT INTO @decod (coloana,coloana_asis, valoare)
	select 
		gs.descriere,semnificatie_asis, SUBSTRING (st.string,CHARINDEX(')',st.string)+1, LEN(st.string))
	from dbo.fSplit(@cod,'(') st
	JOIN GS1_STANDARD gs on REPLACE(SUBSTRING(st.string,1, CHARINDEX(')',st.string)),')','')=gs.ai 

return
end
