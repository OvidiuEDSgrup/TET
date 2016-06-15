create procedure wOPModificareDatePI @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModificareDatePISP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModificareDatePISP @sesiune, @parXML
	return @returnValue
end

begin try
	declare @numar varchar(30), @data datetime, @tip varchar(2), @numar_pozitie int, @idPozPlin int, @dataplatii datetime, @cont varchar(40), @o_data datetime,
		@contcorespondent varchar(40),@sub varchar(9), @bugetari int, @o_contcorespondent varchar(40), @cotatva float, @sumatva float, @o_cotatva float, @o_sumatva float, 
		@parXMLDetalii xml, @detalii xml, @indbug varchar(20), @o_indbug varchar(20), @idPozplinCoresp int, @detaliiCoresp xml, @contAntetCoresp varchar(40)
	
	select @numar=@parXML.value('(/parametri/row/@numar)[1]','varchar(30)'),
		@numar_pozitie=@parXML.value('(/parametri/row/@numarpozitie)[1]','int'),
		@idPozPlin=@parXML.value('(/parametri/row/@idPozPlin)[1]','int'),
		@data=@parXML.value('(/parametri/@data)[1]','datetime'),
		@o_data=@parXML.value('(/parametri/@o_data)[1]','datetime'),
		@cont=@parXML.value('(/parametri/@cont)[1]','varchar(40)'),
		@contcorespondent=@parXML.value('(/parametri/@contcorespondent)[1]','varchar(40)'),
		@o_contcorespondent=@parXML.value('(/parametri/@o_contcorespondent)[1]','varchar(40)'),
		@dataplatii=isnull(@parXML.value('(/parametri/@dataplatii)[1]','datetime'),'1901-01-01'),
		@cotatva=@parXML.value('(/parametri/@cotatva)[1]','float'),
		@o_cotatva=@parXML.value('(/parametri/@o_cotatva)[1]','float'),
		@sumatva=@parXML.value('(/parametri/@sumatva)[1]','float'),
		@o_sumatva=@parXML.value('(/parametri/@o_sumatva)[1]','float'),
		@tip=@parXML.value('(/parametri/@tip)[1]','varchar(2)'),
		@indbug = isnull(@parXML.value('(/parametri[1]/detalii/row/@indicator)[1]','varchar(20)'),''),
		@o_indbug = isnull(@parXML.value('(/parametri[1]/o_detalii/row/@indicator)[1]','varchar(20)'),'')
		
	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec luare_date_par 'GE','BUGETARI',@bugetari output,0,''
	
	if @contcorespondent<>@o_contcorespondent 
		and exists (select 1 from pozplin p inner join facturi f on f.Subunitate=p.Subunitate and f.Factura=p.Factura and p.Tert=f.Tert and f.valoare<>0 
			and p.Cont=@cont and p.Data=@data and p.Numar=@numar and p.Numar_pozitie=@numar_pozitie and isnull(p.Factura,'')<>'')-- and p.Factura not like 'AVANS%')
		raiserror ('Modificarea contului corespondent pe aceasta pozitie ar genera necorelatii!',11,1)	

	select @detalii=detalii from pozplin
	where idPozPlin=@idPozPlin

	if @dataplatii<>'01/01/1901'
	begin
		set @parXMLDetalii=(select 'dataplatii' as atribut, convert(char(10),@dataplatii,101) as valoare for xml raw)
		exec ActualizareInXml @parXMLDetalii, @detalii output
	end
	
	/*	completare in pozplin.detalii a indicatorului bugetar modificat */
	if @indbug<>@o_indbug
	begin
		set @parXMLDetalii=(select 'indicator' as atribut, rtrim(@indbug) as valoare for xml raw)
		exec ActualizareInXml @parXMLDetalii, @detalii output
	end

	/*	completare in pozplin.detalii a indicatorului bugetar modificat, pentru documente prin 482 (documentul corespondent) */
	if @bugetari=1 and @contcorespondent like '482%' and @indbug<>@o_indbug
	begin
		--	caut idPozplin si detalii de pe pozitia prin 482 corespondenta celei curente (regula este cea din triggerul de validare).
		select @idPozplinCoresp=pp.idPozplin, @detaliiCoresp=pp.detalii, @contAntetCoresp=pp.cont 
		from pozplin pp 
			inner join pozplin pc on pp.subunitate=pc.subunitate and pc.idPozPlin=@idPozPlin 
				and pp.data=pc.data and pp.numar_pozitie=pc.numar_pozitie and pp.factura=pc.factura and pp.tert=pc.Tert
				and (pp.cont=pc.cont_corespondent and pp.numar=pc.numar
						and (pp.Plata_incasare=pc.Plata_incasare --	deconturi si mai jos conditia pentru facturi
							or (pp.Plata_incasare='PF' and pc.Plata_incasare='PD') or (pp.Plata_incasare='IB' and pc.Plata_incasare='ID'))
					--	mai jos este conditia pentru corespondenta PD<->ID (utilizata la ABA Mures)
					or pp.cont=pc.cont and pp.numar=rtrim(pc.numar)+'.' and pp.Plata_incasare='ID' and pc.Plata_incasare='PD')
	end

	update pozplin set 
		data=(case when @data!=@o_data and @o_data=data then @data else data end),
		Cont_corespondent=(case when @contcorespondent<> @o_contcorespondent and @o_contcorespondent=Cont_corespondent then @contcorespondent else Cont_corespondent end), 
		TVA11 =(case when @cotatva<> @o_cotatva and @o_cotatva=TVA11 then @cotatva else TVA11 end), 
		TVA22 =(case when @sumatva<> @o_sumatva and @o_sumatva=TVA22 then @sumatva else TVA22 end),
		detalii=@detalii
	where idPozPlin=@idPozPlin
		and not (@idPozplinCoresp is not null)	-- sa nu se faca update pe pozitia curenta daca se modifica indicatorul bugetar.

	if @idPozplinCoresp is not null
	begin 
		begin tran modIndbugPozplin
		alter table pozplin disable trigger tr_validpozplin482
		
		/*	modificare detalii (indicator) pe pozitia curenta */
		update pozplin set detalii=@detalii
		where idPozPlin=@idPozPlin

		set @parXMLDetalii=(select 'indicator' as atribut, rtrim(@indbug) as valoare for xml raw)
		exec ActualizareInXml @parXMLDetalii, @detaliiCoresp output

		/*	modificare detalii (indicator) pe pozitia corespondenta */
		update pozplin set detalii=@detaliiCoresp
		where idPozPlin=@idPozPlinCoresp
		alter table pozplin enable trigger tr_validpozplin482
		-->generare inregistrari contabile
		exec faInregistrariContabile @dinTabela=0, @Subunitate=@sub, @Tip='PI', @Numar=@contAntetCoresp, @Data=@data
		commit tran modIndbugPozplin
	end

end try 
begin catch
	if EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'modIndbugPozplin')
		ROLLBACK TRAN modIndbugPozplin

	declare @error varchar(500)
	set @error=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@error,16,1)
end catch

/* 
select * from pozplin
sp_help pozplin
*/
