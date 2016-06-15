create procedure wOPModificareDatePIValuta @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareDatePIValutaSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareDatePIValutaSP @sesiune, @parXML
	return @returnValue
end

begin try
	declare @sub varchar(9), @numar varchar(30), @data datetime, @tip varchar(2), @idPozPlin int, @cont varchar(40), 
		@contdifcurs varchar(40), @o_contdifcurs varchar(40), @sumadifcurs float, @o_sumadifcurs float, @suma float, @o_suma float, 
		@detaliiRow xml, @detaliiPoz xml
	
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	
	select @numar=@parXML.value('(/parametri/row/@numar)[1]','varchar(30)'),
		@idPozPlin=@parXML.value('(/parametri/row/@idPozPlin)[1]','int'),
		@data=@parXML.value('(/parametri/@data)[1]','datetime'),
		@cont=@parXML.value('(/parametri/@cont)[1]','varchar(40)'),
		@contdifcurs=@parXML.value('(/parametri/@contdifcurs)[1]','varchar(40)'),
		@o_contdifcurs=@parXML.value('(/parametri/@o_contdifcurs)[1]','varchar(40)'),
		@sumadifcurs=@parXML.value('(/parametri/@sumadifcurs)[1]','float'),
		@o_sumadifcurs=@parXML.value('(/parametri/@o_sumadifcurs)[1]','float'),
		@suma=@parXML.value('(/parametri/@suma)[1]','float'),
		@o_suma=@parXML.value('(/parametri/@o_suma)[1]','float'),
		@tip=@parXML.value('(/parametri/@tip)[1]','varchar(2)'),
		@detaliiPoz=@parXML.query('/parametri[1]/detalii/row'),
		@detaliiRow=@parXML.query('/parametri[1]/row/detalii/row')

	update pozplin set 
		Suma=(case when @suma<>@o_suma and @o_suma=Suma then @suma else Suma end),
		Cont_dif=(case when @contdifcurs<>@o_contdifcurs and @o_contdifcurs=Cont_dif then @contdifcurs else Cont_dif end), 
		Suma_dif=(case when @sumadifcurs<>@o_sumadifcurs and @o_sumadifcurs=Suma_dif then @sumadifcurs else Suma_dif end),
		detalii=(case when @detaliiPoz is not null --and convert(varchar(max),@detaliiPoz)<>convert(varchar(max),@detaliiRow) and convert(varchar(max),@detaliiRow)=convert(varchar(max),detalii) 
					then @detaliiPoz else detalii end)
	where idPozPlin=@idPozPlin

end try 
begin catch
	declare @error varchar(500)
	set @error=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@error,16,1)
end catch

/* 
select * from pozplin
sp_help pozplin
*/
