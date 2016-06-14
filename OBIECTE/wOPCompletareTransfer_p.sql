--***
if exists (select * from sysobjects where name ='wOPCompletareTransfer_p')
drop procedure wOPCompletareTransfer_p
go
--***
/****** Object:  StoredProcedure [dbo].[wOPModificareAntetCon_p]    Script Date: 04/06/2011 10:58:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--***
create procedure wOPCompletareTransfer_p @sesiune varchar(50), @parXML xml 
as  
begin try
	declare @numar varchar(20),@mesaj varchar(500),@tip varchar(2), @subtip varchar(2),@tert varchar(13),@data datetime,@sub varchar(9),
		@gestiune varchar(13),@gestPrim varchar(13),@categPret varchar(13),@numarDoc varchar(13),@tipDoc varchar(2),
		@utilizator varchar(20),@stare int

	select 
		@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@tert=upper(ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), '')),
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),
		@stare=upper(ISNULL(@parXML.value('(/row/@stare)[1]', 'int'), 0)),
		@gestPrim=ISNULL(@parXML.value('(/row/@gestprim)[1]', 'varchar(13)'), ''),
		@tipDoc='TE'

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output-->identificare utilizator pe baza sesiunii
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output --> citire subunitate din proprietati     

	/*if @stare not in ('6','1','4')
		select '    Pentru facturare, comanda de livrare trebuie sa fie in stare "1-Aprobat", sau "6-Facturat"!' 
			as textMesaj, 'Mesaj avertizare' as titluMesaj 
		for xml raw, root('Mesaje')*/
		
	if ISNULL(@tert,'')=''
		select '    Pentru facturare, pe comanda de livrare trebuie sa fie definit beneficiarul!' 
			as textMesaj, 'Mesaj avertizare' as titluMesaj 
		for xml raw, root('Mesaje')	
	
	/*if isnull(@numarDoc,'')=''--daca nu s-a introdus numar pt TE se ia urmatorul numar din plaja
	begin 
		declare @fXML xml, @NrDocFisc varchar(10)
		set @fXML = '<row/>'
		set @fXML.modify ('insert attribute tipmacheta {"O"} into (/row)[1]')
		set @fXML.modify ('insert attribute tip {sql:variable("@tipDoc")} into (/row)[1]')
		set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		exec wIauNrDocFiscale @parXML=@fXML, @Numar=@NrDocFisc output
		set @numarDoc=@NrDocFisc
	end*/
		
	SELECT @numarDoc AS numardoc ,@tert+ ' - ' +rtrim((select denumire from terti where tert=@tert))  as dentert
	FOR XML raw, root('Date')
	
	SELECT (    
		select rtrim(p.cod) as cod, 
			--> in transfer se va duce cantitatea aprobata ramasa netransferata(Pret_promotional->camp refolosit pentru cant. transferata)
			convert(varchar(20),(p.cant_aprobata-p.cant_realizata)) as cantitate_factura,
			convert(varchar(20),(p.cant_aprobata-p.cant_realizata)) as cantitate_disponibila, 
			
			-->pretul cu amnuntul se ia din dreptul categoriei de pret
			isnull(convert(varchar(20),(select top 1 pret_cu_amanuntul from preturi where cod_produs=p.cod and um=@CategPret 
				order by data_inferioara desc)),0) as pamanunt,
			rtrim(n.Denumire) as denumire, convert(varchar(20),p.Cant_aprobata) as cant_aprobata, convert(varchar(20),p.cant_realizata) as cant_realizata,
			RTRIM(p.Subunitate) as subunitate,RTRIM(p.tip) as tip, convert(varchar(10),p.data,101)as data, RTRIM(p.Contract) as contract, RTRIM(p.Tert) as tert,
			Numar_pozitie as numar_pozitie	
		from pozcon p
			left outer join nomencl n on p.Cod=n.Cod 
		where p.Subunitate=@sub and p.tip='BK' 
			and p.contract=@numar and (p.tert='' or p.tert=@tert) and p.data=@data
	  FOR XML raw, type  
	  )  
	FOR XML path('DateGrid'), root('Mesaje')

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch