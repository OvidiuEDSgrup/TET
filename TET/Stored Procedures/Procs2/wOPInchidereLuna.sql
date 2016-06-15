
Create procedure wOPInchidereLuna @sesiune varchar(50), @parXML xml
as
begin try
	declare 
		@luna int, @luna_alfa varchar(20), @anul int, @data datetime,
		@luna_actual int, @anul_actual int, @data_actual datetime,
		@context varbinary(128), @mesaj varchar(2000), @tip_necorelatii varchar(20), @utilizator varchar(100)

	if exists (select * from sysobjects where name ='wJurnalizareOperatie' and type='P')
		exec wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql='wOPInchidereLuna'

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	select 
		@luna = ISNULL(@parXML.value('(/*/@luna)[1]', 'int'), '0'),
		@anul = ISNULL(@parXML.value('(/*/@anul)[1]', 'int'), '0')
	
	if @anul=0 or @luna=0
		raiserror('Selectati anul si luna care se inchid!' ,16,1)

	select
		@data=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@anul,4))),
		@luna_alfa=(case @luna when 1 then 'Ianuarie' when 2 then 'Februarie' when 3 then 'Martie' when 4 then 'Aprilie' when 5 then 'Mai' when 6 then 'Iunie' when 7 then 'Iulie'
						when 8 then 'August' when 9 then 'Septembrie' when 10 then 'Octombrie' when 11 then 'Noiembrie'	else 'Decembrie' end)
						
	/* Ultima luna initializata stocuri */
	SELECT TOP 1 @luna_actual=isnull(val_numerica,1) from par where tip_parametru='GE' and parametru='LUNABLOC'
	SELECT TOP 1 @anul_actual=isnull(val_numerica,1901) from par where tip_parametru='GE' and parametru='ANULBLOC'
	SELECT @data_actual=dbo.eom(convert(datetime,str(@luna_actual,2)+'/01/'+str(@anul_actual,4)))
/*
	/* Nu putem inchide luna daca exista necorelatii realizate prin documente necontate la o data anterioara*/
	IF EXISTS (select 1 from DocDeContat where data<=@data)
		raiserror('Exista documente fara inregistrari contabile la o data anterioara. Utilizati unealta de "Verificare contabilitate" pentru a rezolva necorelatiile!', 16,1)

	delete from Necorelatii where utilizator=@utilizator
	select @tip_necorelatii='SC'
	/* Nu putem inchide luna daca exista necorelatii stocuri de la data anterioara inchisa la data care se doreste inchisa*/
	exec populareNecorelatii @Data_jos=@data_actual, @Data_sus=@data,@PretAm=0,@Tip_necorelatii=@tip_necorelatii,@InUM2=0,@FiltruCont='',
			@FiltruGest=null,@FiltruCod_intrare=null,@FiltruGrupa=null,@TipStoc=null,@FiltruCod=null,@FiltruLM=null,@FiltruComanda=null,
			@FiltruFurn=null,@FiltruLot=null,@FiltruLocatie=null,@CorelatiiPeContAtribuit=1,@FiltruContCor=null,@RulajePeLocMunca=0,@Valuta=''	
	 
	 IF EXISTS (select 1 from Necorelatii where utilizator=@utilizator)
		raiserror('Exista necorelatii stocuri. Utilizati unealta de "Verificare contabilitate" pentru a le rezolva inainte de a inchide luna!', 16,1)

	select @tip_necorelatii='BE'
	/* Nu putem inchide luna daca exista necorelatii stocuri de la data anterioara inchisa la data care se doreste inchisa*/
	exec populareNecorelatii @Data_jos=@data_actual, @Data_sus=@data,@PretAm=0,@Tip_necorelatii=@tip_necorelatii,@InUM2=0,@FiltruCont='',
			@FiltruGest=null,@FiltruCod_intrare=null,@FiltruGrupa=null,@TipStoc=null,@FiltruCod=null,@FiltruLM=null,@FiltruComanda=null,
			@FiltruFurn=null,@FiltruLot=null,@FiltruLocatie=null,@CorelatiiPeContAtribuit=1,@FiltruContCor=null,@RulajePeLocMunca=0,@Valuta=''	
	 
	 IF EXISTS (select 1 from Necorelatii where utilizator=@utilizator)
		raiserror('Exista necorelatii beneficiari. Utilizati unealta de "Verificare contabilitate" pentru a le rezolva inainte de a inchide luna!', 16,1)

	select @tip_necorelatii='FU'
	/* Nu putem inchide luna daca exista necorelatii stocuri de la data anterioara inchisa la data care se doreste inchisa*/
	exec populareNecorelatii @Data_jos=@data_actual, @Data_sus=@data,@PretAm=0,@Tip_necorelatii=@tip_necorelatii,@InUM2=0,@FiltruCont='',
			@FiltruGest=null,@FiltruCod_intrare=null,@FiltruGrupa=null,@TipStoc=null,@FiltruCod=null,@FiltruLM=null,@FiltruComanda=null,
			@FiltruFurn=null,@FiltruLot=null,@FiltruLocatie=null,@CorelatiiPeContAtribuit=1,@FiltruContCor=null,@RulajePeLocMunca=0,@Valuta=''	
	 
	 IF EXISTS (select 1 from Necorelatii where utilizator=@utilizator)
		raiserror('Exista necorelatii furnizori. Utilizati unealta de "Verificare contabilitate" pentru a le rezolva inainte de a inchide luna!', 16,1)

	select @tip_necorelatii='TC'
	/* Nu putem inchide luna daca exista necorelatii stocuri de la data anterioara inchisa la data care se doreste inchisa*/
	exec populareNecorelatii @Data_jos=@data_actual, @Data_sus=@data,@PretAm=0,@Tip_necorelatii=@tip_necorelatii,@InUM2=0,@FiltruCont='',
			@FiltruGest=null,@FiltruCod_intrare=null,@FiltruGrupa=null,@TipStoc=null,@FiltruCod=null,@FiltruLM=null,@FiltruComanda=null,
			@FiltruFurn=null,@FiltruLot=null,@FiltruLocatie=null,@CorelatiiPeContAtribuit=1,@FiltruContCor=null,@RulajePeLocMunca=0,@Valuta=''	
	 
	 IF EXISTS (select 1 from Necorelatii where utilizator=@utilizator)
		raiserror('Exista necorelatii TVA colectat. Utilizati unealta de "Verificare contabilitate" pentru a le rezolva inainte de a inchide luna!', 16,1)

	select @tip_necorelatii='TD'
	/* Nu putem inchide luna daca exista necorelatii stocuri de la data anterioara inchisa la data care se doreste inchisa*/
	exec populareNecorelatii @Data_jos=@data_actual, @Data_sus=@data,@PretAm=0,@Tip_necorelatii=@tip_necorelatii,@InUM2=0,@FiltruCont='',
			@FiltruGest=null,@FiltruCod_intrare=null,@FiltruGrupa=null,@TipStoc=null,@FiltruCod=null,@FiltruLM=null,@FiltruComanda=null,
			@FiltruFurn=null,@FiltruLot=null,@FiltruLocatie=null,@CorelatiiPeContAtribuit=1,@FiltruContCor=null,@RulajePeLocMunca=0,@Valuta=''	
	 
	 IF EXISTS (select 1 from Necorelatii where utilizator=@utilizator)
		raiserror('Exista necorelatii TVA deductibil. Utilizati unealta de "Verificare contabilitate" pentru a le rezolva inainte de a inchide luna!', 16,1)
*/

	/* Actualizare in PAR cu CONTEXT_INFO deoarece aici este singurul loc unde este permisa modificarea lunii blocate*/
	SELECT @context=convert(varbinary(128),'opinchluna')
	SET CONTEXT_INFO @context  

		exec setare_par 'GE','LUNABLOC','Ultima luna blocata',0,@luna,@luna_alfa
		exec setare_par 'GE','ANULBLOC','Anul ultimei luni blocate',0,@anul,''

	SET CONTEXT_INFO 0x

	select 'Luna inchisa cu succes!' as textMesaj, 'Notificare' as titluMesaj for xml raw, root('Mesaje')
end try
begin catch
	SET CONTEXT_INFO 0x
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
