
CREATE procedure wRapFisaLansareOp_p @sesiune varchar(20), @parXML xml
as

	select @parXML for xml path('Date'), type
