--***
/**	proc. generare codbara OP	*/
Create procedure ptGenerare_codbara_OP (@cTerm char(8))
As
DECLARE @cmd sysname, @Cmd1 varchar(1000), @Cmd2 varchar(1000), @Cale_fisiere varchar(200), @Codbara char(1000), @Nume_server char(100), @Nume_bd char(100), @Generare_codbara_declaratii int
Exec Luare_date_par 'PS', 'GCODBDECL', @Generare_codbara_declaratii output , 0, 0
Set @Cale_fisiere= ''
Set @Cale_fisiere = dbo.iauParA('PS','CALEFCODB')
if @Cale_fisiere=''
	Set @Cale_fisiere='C:\Windows\System32\'
Set @Nume_server=convert(char(100),(select serverproperty('servername')))
Set @Nume_bd=(select db_name())
-- formare fisier cbare.txt
if @Generare_codbara_declaratii=0
	Select @Codbara='#'+rtrim(numar_document)+'#,'+rtrim(ltrim(convert(char(15),convert(money,suma))))+',#'+rtrim(Platitor)+'#,'+ rtrim(Cif_platitor)+',#'+rtrim(Adresa)+'#,#'+rtrim(Cont_iban_platitor)+'#,#'+rtrim(Cod_banca_platitor)+'#,#'+rtrim(Beneficiar)+'#,'+
	rtrim(Cif_beneficiar)+',#'+rtrim(Cont_iban_beneficiar)+'#,#'+rtrim(Cod_banca_beneficiar)+'#,,#'+rtrim(Explicatii)+'#,'+
	convert(char(10),Data_emiterii,103)
	from fPlati_trezorerie () 
Else
	Set @Codbara=(select rtrim(dbo.fSir_codbara_declaratii()))

If exists (Select * from sysobjects where name = 'declmftxt' and type = 'U')
	drop table declmftxt

create table declmftxt (text1 char(2000) not null default '')
Insert into declmftxt(text1) select @Codbara
Set @Cmd1='master..xp_cmdshell '+char(39)+'bcp "Select rtrim(text1) from '+rtrim(@Nume_bd)+'.dbo.declmftxt" queryout '+ rtrim(@Cale_fisiere)+'cbare.txt -n -c -C -T -U sa -S '+rtrim(@Nume_server)+ char(39)
exec (@Cmd1)
-- formare fisier coduri_bara.bat pt. a putea lansa coduri_bara.exe din orice director
If exists (Select * from sysobjects where name = 'declmftxt1' and type = 'U') 
	drop table declmftxt1
create table declmftxt1 (text1 char(2000) not null default '')
insert into declmftxt1 select left(ltrim(@Cale_fisiere),2)
insert into declmftxt1 select 'cd '+ltrim(rtrim(@Cale_fisiere))
insert into declmftxt1 select 'coduri_bara.exe'
Set @cmd2='master..xp_cmdshell '+char(39)+'bcp "Select rtrim(text1) from '+rtrim(@nume_bd)+'.dbo.declmftxt1" queryout '+ 
rtrim(@cale_fisiere)+'coduri_bara.bat -n -c -C -T -U sa -S '+rtrim(@nume_server)+ char(39)
exec (@Cmd2)
-- generare cod de bara
SET @Cmd=rtrim(@Cale_fisiere)+'coduri_bara.bat'
exec master..xp_cmdshell @Cmd, no_output
return
