--***
Create procedure wOPRefacereRulajeContParinte @sesiune varchar(50), @parXML xml
as

Begin
	declare @datal datetime, @lunaalfa varchar(15), @luna int, @an int, 
	@datas datetime, @cont varchar(40), @dencont varchar(80), 
	@lunabloc int,@anulbloc int, @databloc datetime, 
	@refacere int	--	0 = refacere rulaj luna, 1 = refacere sold inceput de an

	if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
		exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPRefacereRulajeContParinte'

	set @datal = ISNULL(@parXML.value('(/parametri/@datal)[1]', 'datetime'), '12/31/2999')
	set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
	set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
	set @refacere = ISNULL(@parXML.value('(/parametri/@refacere)[1]', 'int'), 0)

	/*	Refacere rulaj luna. */
	if @refacere=0
	begin
		if @luna<>0 and @an<>0
			set @datal=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))
		set @datas = dbo.eom(@datal)
	end

	/*	Refacere sold inceput de an. */
	if @refacere=1
	begin
		if @an<>0
			set @datal=convert(datetime,str('01',2)+'/01/'+str(@an,4))
		else 
			set @datal=dbo.boy(@datal)
		set @datas = @datal
	end
	select @lunaalfa=LunaAlfa from fCalendar(@datas,@datas)

	set @cont = ISNULL(@parXML.value('(/parametri/@cont)[1]', 'varchar(40)'), '')
	select @dencont=isnull(Denumire_cont,'') from conturi where cont=@cont

	set @lunabloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='LUNABLOC'), 1)
	set @anulbloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru='ANULBLOC'), 1901)
	if @lunabloc not between 1 and 12 or @anulbloc<=1901 
		set @databloc='01/31/1901'
	else 
		set @databloc=dbo.eom(convert(datetime,str(@lunabloc,2)+'/01/'+str(@anulbloc,4)))

	begin try  
		if @refacere=0 and (@luna=0 or @an=0)
			raiserror('Alegeti luna si anul!' ,16,1)
		if @refacere=1 and @an=0
			raiserror('Alegeti anul!' ,16,1)
		if @cont<>'' and not exists (select 1 from conturi where cont=@cont)
			raiserror('Cont inexistent!' ,16,1)
		if @datas<=@databloc
			raiserror('Luna aleasa este blocata!' ,16,1)

		exec RefacereRulajeParinte @dDataJos=@datas, @dDataSus=@datas, @cCont=@cont, @nInLei=1, @nInValuta=1, @cValuta='', @SiSoldIncAn=@refacere

		select 'Terminat operatie!' as textMesaj, 
		'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')
	end try  

	begin catch
		declare @eroare varchar(254) 
		set @eroare=ERROR_MESSAGE()
		raiserror(@eroare, 16, 1) 
	end catch
end
