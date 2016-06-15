
create procedure wOPFiltrareComenziDePrelucrat @sesiune varchar(50),@parXML xml
as
begin
	-- apelare procedura specIFica daca aceASta exista.
	IF EXISTS (SELECT 1 FROM sysobjects where [type]='P' AND [name]='wOPFiltrareComenziDePrelucratSP')
	BEGIN 
		DECLARE @returnValue INT -- variabila salveaza return value de la procedura specIFica
		EXEC @returnValue = wOPFiltrareComenziDePrelucratSP @sesiune, @parXML OUTPUT
		RETURN @returnValue
	END

	declare 
		@datajos datetime, @datasus datetime, @lm varchar(20),@gestiune varchar(20),@tert varchar(20), @utilizator varchar(100)


	select
		@datajos		=	ISNULL(@parXML.value('(/*/@datajos)[1]','datetime'),DATEADD(YEAR,-50,GETDATE())),
		@datasus		=	ISNULL(@parXML.value('(/*/@datasus)[1]','datetime'),DATEADD(YEAR,50,GETDATE()))

	IF OBJECT_ID('tmpComenziDePrelucrat') IS NULL
		create table tmpComenziDePrelucrat (utilizator varchar(100), idContract int)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	insert into tmpComenziDePrelucrat (utilizator, idContract)
	select
		@utilizator, idContract
	from Contracte where tip='CL' and data between @datajos and @datasus and 
		(ISNULL(@tert,'')='' or tert=@tert) and (ISNULL(@lm,'')='' or loc_de_munca=@lm) and (ISNULL(@gestiune,'')='' OR gestiune=@gestiune)
	and NOT EXISTS (select 1 from tmpComenziDePrelucrat where idContract=Contracte.idContract)
end

