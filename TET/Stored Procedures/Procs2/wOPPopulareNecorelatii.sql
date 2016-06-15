--***
create procedure wOPPopulareNecorelatii (@sesiune varchar(50), @parXML xml)   
as       
--apelare procedura specifica daca aceasta exista
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPPopulareNecorelatiiSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPPopulareNecorelatiiSP @sesiune, @parXML output
	return @returnValue
end
declare @utilizator varchar(8),@mesaj varchar(200)
          
begin try  
	/*se apeleaza wIaUtilizator cu par expliciti*/
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output 
	declare @tip_necorelatii varchar(2) ,@data_jos datetime,@data_sus datetime,@corelatiiPeContAtribuit int,@rulajePeLocMunca int,@valuta varchar(3),
		@filtruCont varchar(40)
	  
	select @tip_necorelatii=isnull(@parXML.value('(/parametri/@tip)[1]','char(2)'),''),
		@valuta=isnull(@parXML.value('(/parametri/@valuta)[1]','char(3)'),''),
		@filtruCont=isnull(@parXML.value('(/parametri/@filtruCont)[1]','varchar(40)'),''),
		@corelatiiPeContAtribuit=isnull(@parXML.value('(/parametri/@corelatiiPeContAtribuit)[1]','int'),1), --am pus 1, fiindca deocamdata nu tratam necorelatiile pe conturi neatribuite
		@rulajePeLocMunca=isnull(@parXML.value('(/parametri/@rulajePeLocMunca)[1]','int'),0),
		@data_jos = isnull(@parXML.value('(/parametri/@datajos)[1]','datetime'),'1901-01-01'),
		@data_sus = isnull(@parXML.value('(/parametri/@datasus)[1]','datetime'),'2099-01-01')
	
	exec populareNecorelatii @Data_jos=@data_jos, @Data_sus=@data_sus,@PretAm=0,@Tip_necorelatii=@tip_necorelatii,@InUM2=0,@FiltruCont=@filtruCont,
		@FiltruGest=null,@FiltruCod_intrare=null,@FiltruGrupa=null,@TipStoc=null,@FiltruCod=null,@FiltruLM=null,@FiltruComanda=null,
		@FiltruFurn=null,@FiltruLot=null,@FiltruLocatie=null,@CorelatiiPeContAtribuit=@corelatiiPeContAtribuit,@FiltruContCor=null,
		@RulajePeLocMunca=@rulajePeLocMunca,@Valuta=@valuta	

	select 'Tabela de necorelatii a fost repopulata!' as textMesaj, 'Finalizare operatie' as titluMesaj   
	for xml raw, root('Mesaje')
end try
  
begin catch  
	set @mesaj = '(wOPPopulareNecorelatii)'+ERROR_MESSAGE()  
end catch		

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
