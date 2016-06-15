--***
Create procedure wOPRefacereAntetDocumente @sesiune varchar(50), @parXML xml
as

declare @sub char(9), --@lunainch int, @anulinch int, @datainch datetime, 
@nrdoc char(20), --@tipdoc char(2), @datadoc datetime, 
@datainf datetime, @datasup datetime, @RM int, @RS int, @RC int, @PP int, @CM int, @AP int, @AS int, 
@AC int, @TE int, @DF int, @PF int, @CI int, @AF int, @AI int, @AE int, @PI int, @AD int, @NC int, 
@IC int, @mesajeroare varchar(254)--, @userASiS varchar(10)

--exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
	exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPRefacereAntetDocumente'

Set @sub=isnull((select max(Val_alfanumerica) from par where tip_parametru='GE' and 
parametru='SUBPRO'), '')
/*Set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
parametru='LUNAINC'), 1)
Set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
parametru='ANULINC'), 1901)
if @lunainch not between 1 and 12 or @anulinch<=1901 
	set @datainch='01/31/1901'
else 
	set @datainch=dbo.eom(convert(datetime,str(@lunainch,2)+'/01/'+str(@anulinch,4)))*/
Set @nrdoc = ISNULL(@parXML.value('(/parametri/@nrdoc)[1]', 'char(20)'), '')
/*Set @tipdoc = ISNULL(@parXML.value('(/parametri/@tipdoc)[1]', 'char(20)'), '')
Set @datadoc = ISNULL(@parXML.value('(/parametri/@datadoc)[1]', 'datetime'), '01/01/1901')*/
Set @datainf = ISNULL(@parXML.value('(/parametri/@datainf)[1]', 'datetime'), '01/01/1901')
Set @datasup = ISNULL(@parXML.value('(/parametri/@datasup)[1]', 'datetime'), '01/01/1901')
Set @RM = ISNULL(@parXML.value('(/parametri/@RM)[1]', 'int'), 0)
Set @RS = ISNULL(@parXML.value('(/parametri/@RS)[1]', 'int'), 0)
Set @RC = ISNULL(@parXML.value('(/parametri/@RC)[1]', 'int'), 0)
Set @PP = ISNULL(@parXML.value('(/parametri/@PP)[1]', 'int'), 0)
Set @CM = ISNULL(@parXML.value('(/parametri/@CM)[1]', 'int'), 0)
Set @AP = ISNULL(@parXML.value('(/parametri/@AP)[1]', 'int'), 0)
Set @AS = ISNULL(@parXML.value('(/parametri/@AS)[1]', 'int'), 0)
Set @AC = ISNULL(@parXML.value('(/parametri/@AC)[1]', 'int'), 0)
Set @TE = ISNULL(@parXML.value('(/parametri/@TE)[1]', 'int'), 0)
Set @DF = ISNULL(@parXML.value('(/parametri/@DF)[1]', 'int'), 0)
Set @PF = ISNULL(@parXML.value('(/parametri/@PF)[1]', 'int'), 0)
Set @CI = ISNULL(@parXML.value('(/parametri/@CI)[1]', 'int'), 0)
Set @AF = ISNULL(@parXML.value('(/parametri/@AF)[1]', 'int'), 0)
Set @AI = ISNULL(@parXML.value('(/parametri/@AI)[1]', 'int'), 0)
Set @AE = ISNULL(@parXML.value('(/parametri/@AE)[1]', 'int'), 0)
Set @PI = ISNULL(@parXML.value('(/parametri/@PI)[1]', 'int'), 0)
Set @AD = ISNULL(@parXML.value('(/parametri/@AD)[1]', 'int'), 0)
Set @NC = ISNULL(@parXML.value('(/parametri/@NC)[1]', 'int'), 0)
Set @IC = ISNULL(@parXML.value('(/parametri/@IC)[1]', 'int'), 0)

begin try
	if @nrdoc<>'' and @PI+@AD+@NC+@IC>0
		raiserror('Daca ati completat nr. doc., nu bifati "Inregistrari contabile" sau "Note contabile" sau "Alte documente" sau "Plati si incasari"!' ,16,1)
	if @nrdoc<>'' and @RM+@RS+@RC+@PP+@CM+@AP+@AS+@AC+@TE+@DF+@PF+@CI+@AF+@AI+@AE+@PI+@AD+@NC+@IC>1
		raiserror('Daca ati completat nr. doc., bifati doar un tip de document!' ,16,1)
	if @RM+@RS+@RC+@PP+@CM+@AP+@AS+@AC+@TE+@DF+@PF+@CI+@AF+@AI+@AE+@PI+@AD+@NC+@IC=0
		raiserror('Bifati cel putin un tip de document!' ,16,1)
	if @datasup<@datainf
		raiserror('Data superioara < data inferioara!' ,16,1)
	/*if @datainf<=@datainch set @mesajeroare='Data inferioara <= '+CONVERT(char(10),@datainch,103)+' (ultima zi a ultimei luni inchise)!'
	if @datainf<=@datainch
		raiserror(@mesajeroare ,16,1)*/
	if @nrdoc<>'' and @datainf<>@datasup
		raiserror('Daca ati completat nr. doc., data inferioara trebuie sa fie egala cu data superioara!' ,16,1)
	if @nrdoc<>'' and not exists (select 1 from doc where Subunitate=@sub and tip=(case 
		when @RM=1 then 'RM' when @RS=1 then 'RS' when @RC=1 then 'RC' when @PP=1 then 'PP' 
		when @CM=1 then 'CM' when @AP=1 then 'AP' 
		when @AS=1 then 'AS' when @AC=1 then 'AC' when @TE=1 then 'TE' when @DF=1 then 'DF' when 
		@PF=1 then 'PF' when @CI=1 then 'CI' when @AF=1 then 'AF' when @AI=1 then 'AI' when @AE=1 
		then 'AE' else '' end) and Numar=@nrdoc and data=@datainf)
		raiserror('Document inexistent sau de alt tip sau din alta data!' ,16,1)

	if @RM=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='RM', @numar=@nrdoc
	if @RS=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='RS', @numar=@nrdoc
	if @RC=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='RC', @numar=@nrdoc
	if @PP=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='PP', @numar=@nrdoc
	if @CM=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='CM', @numar=@nrdoc
	if @AP=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='AP', @numar=@nrdoc
	if @AS=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='AS', @numar=@nrdoc
	if @AC=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='AC', @numar=@nrdoc
	if @TE=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='TE', @numar=@nrdoc
	if @DF=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='DF', @numar=@nrdoc
	if @PF=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='PF', @numar=@nrdoc
	if @CI=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='CI', @numar=@nrdoc
	if @AF=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='AF', @numar=@nrdoc
	if @AI=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='AI', @numar=@nrdoc
	if @AE=1 exec refaceredoc @dataj=@datainf, @datas=@datasup, @tip='AE', @numar=@nrdoc
	if @PI=1 exec refacereplin @dataj=@datainf, @datas=@datasup, @jurnal='', @cont=@nrdoc
	if @AD=1 exec refacereadoc @dataj=@datainf, @datas=@datasup, @tip='', @numar=@nrdoc
	if @NC=1 exec refacerencon @dataj=@datainf, @datas=@datasup, @tip='', @numar=@nrdoc
	if @IC=1 exec refacereincon @dataj=@datainf, @datas=@datasup

	select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
end try  

begin catch  
	declare @eroare varchar(254) 
	set @eroare=ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
