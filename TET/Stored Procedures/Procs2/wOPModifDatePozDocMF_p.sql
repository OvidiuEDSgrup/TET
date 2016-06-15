create procedure wOPModifDatePozDocMF_p @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModifDatePozDocMF_pSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModifDatePozDocMF_pSP @sesiune, @parXML
	return @returnValue
end

begin try
	declare @subtip varchar(2), @numar varchar(20), @data datetime, @nrinv varchar(20),@procinch float,
		@contgestprim varchar(40), @contlmprim varchar(40), @contamcomprim varchar(40), @indbugprim varchar(30), 
		@denmf varchar(80), @dengestprim varchar(80), @denlmprim varchar(80), @dencomprim varchar(80), 
		@denindbugprim varchar(80)
	select @subtip=@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),
		@numar=@parXML.value('(/row/row/@numar)[1]','varchar(20)'),
		@data=@parXML.value('(/row/row/@data)[1]','datetime'),
		@nrinv=isnull(@parXML.value('(/row/row/@nrinv)[1]','varchar(30)'),''),
		@procinch=isnull(@parXML.value('(/row/row/@procinch)[1]','float'),0),
		@contgestprim=isnull(@parXML.value('(/row/row/@contgestprim)[1]','varchar(40)'),''),
		@contlmprim=isnull(@parXML.value('(/row/row/@contlmprim)[1]','varchar(40)'),''),
		@contamcomprim=isnull(@parXML.value('(/row/row/@contamcomprim)[1]','varchar(40)'),''),
		@indbugprim=isnull(@parXML.value('(/row/row/@indbugprim)[1]','varchar(40)'),'')

	if @nrinv=''
	begin
		select 'wOPModifDatePozDocMF_p: Selectati o pozitie de document!' as textMesaj for xml raw, root('Mesaje')
		return -1
	end  
	
	/*select @numar=numar, @tert=Tert, @subtip=tip, @sumaTVA=tva_deductibil, @pvaluta=Pret_valuta 
	from mismf 
	where Subunitate='1' and Tip_miscare=right(@tip,1)+@subtip 
		numar=@numar and data=@data and numar =@nrinv*/
	
	set @denmf=(select denumire from mfix where left(Subunitate,4)<>'DENS' and Numar_de_inventar=@nrinv)
	set @dengestprim=(select Denumire_gestiune from gestiuni where Cod_gestiune=@contgestprim)
	set @denlmprim=(select denumire from lm where cod=@contlmprim)
	set @dencomprim=(select Descriere from comenzi where Comanda=@contamcomprim)
	set @denindbugprim=(select denumire from indbug where indbug=@indbugprim)
	
	select @subtip subtip, @numar numar, convert(varchar(30),@data,101) data, @nrinv nrinv, 
		@procinch procinch, @contgestprim contgestprim, @contlmprim contlmprim, 
		@contamcomprim contamcomprim, @indbugprim indbugprim, 
		@denmf denmf, @dengestprim dengestprim, @denlmprim denlmprim, @dencomprim dencomprim, 
		@denindbugprim denindbugprim--, convert(decimal(17,5),@pvaluta) pvaluta
	for xml raw
end try 

begin catch
	declare @error varchar(500)
	set @error=ERROR_MESSAGE()
	raiserror(@error,16,1)
end catch
