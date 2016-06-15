--***
create procedure wOPRefacereRulaje @sesiune varchar(50), @parXML xml   
as       
begin try
declare @dataJos datetime, @dataSus datetime
/*declar parametrii pentru procedura de refacere..*/
declare @dDataJos datetime, @dDataSus datetime, @cCont char(13), @nInLei int, @nInValuta int, @cValuta char(3)
select	@dataJos = isnull(@parXML.value('(/parametri/@datajos)[1]','datetime'),'01/01/1901'),
		@dataSus = isnull(@parXML.value('(/parametri/@datasus)[1]','datetime'),'12/31/2999')


exec RefacereRulaje @dDataJos=@dataJos, @dDataSus=@dataSus, @cCont=null, @nInLei=null, @nInValuta=null, @cValuta=null
select 'Refacere rulaje efectuata cu succes!' as textMesaj, 'Finalizare operatie' as titluMesaj for xml raw, root('Mesaje')

end try
begin catch	
	declare @mesajEroare varchar(500)
	set @mesajEroare= '(wOPRefacereRulaje)'+ERROR_MESSAGE()
	raiserror(@mesajEroare,16,1) 
end catch

