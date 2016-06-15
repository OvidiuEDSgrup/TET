--***
/* Procedura apartine machetei de TB ( vizualizare date ) - modifica tipul de grafic in BD conform ceea ce este selectat in frame 
pe macheta de TB*/
CREATE procedure  wScrieTipGraficIndicator  @sesiune varchar(50), @parXML XML 
as
declare @codIndicator varchar(20),@tip varchar(1)

set @codIndicator=isnull(@parXML.value('(/row/@indicator)[1]','varchar(20)'),'')
set @tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(1)'),'')

-- din tabela Indicatori campul Unitate_de_masura este folosit pentru a retine tipul de grafic prin care va fi reprezentat ind.
	update indicatori set Unitate_de_masura = @tip where Cod_Indicator=@codIndicator

