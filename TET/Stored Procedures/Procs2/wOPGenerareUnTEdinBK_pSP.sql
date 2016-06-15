
create procedure wOPGenerareUnTEdinBK_pSP @sesiune varchar(50), @parXML xml 
as  
begin try 
	declare @contract varchar(20),@mesaj varchar(500),@tip varchar(2), @subtip varchar(2),@tert varchar(13),@data datetime,@sub varchar(9),
		@gestiune varchar(13),@gestPrim varchar(13),@gestDest varchar(13),@categPret varchar(13),@numarDoc varchar(13),@tipDoc varchar(2),
		@utilizator varchar(20),@stare int

	select 
		@contract=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@tert=upper(ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(20)'), '')),
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), ''),
		@stare=upper(ISNULL(@parXML.value('(/row/@stare)[1]', 'int'), 0)),
		@gestPrim=ISNULL(@parXML.value('(/row/@gestprim)[1]', 'varchar(13)'), ''),
		@tipDoc='TE'


	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output-->identificare utilizator pe baza sesiunii
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output --> citire subunitate din proprietati     
	
	if isnull(@gestPrim,'')=''
		select '    Pentru efectuarea transferului, comanda de livrare trebuie sa aiba completata gestiunea primitoare!' 
			as textMesaj, 'Mesaj avertizare' as titluMesaj 
		for xml raw, root('Mesaje')

	if @stare not in ('1')
		select '    Pentru efectuarea transferului, comanda de livrare trebuie sa fie in stare "1-Definitiv"!' 
			as textMesaj, 'Mesaj avertizare' as titluMesaj 
		for xml raw, root('Mesaje')
		
	create table #dateGenDoc (tipdoc varchar(2))
	insert into #dateGenDoc(tipdoc) values ('TE')
	exec yso_creezDateGenDoc
	exec yso_populezDateGenDoc @sesiune, @parXML
	
	SELECT *
	FROM #dateGenDoc
	FOR XML raw, root('Date')

	SELECT (    
		select rtrim(p.cod) as cod, 
			--> in transfer se va duce cantitatea aprobata ramasa netransferata(Pret_promotional->camp refolosit pentru cant. transferata)
			convert(varchar(20),(p.cant_aprobata-p.Pret_promotional)) as cant_doc,
			convert(varchar(20),(p.cant_aprobata-p.Pret_promotional)) as cant_disponibila, 
			gestiune=(case @stare when '1' then @gestiune when '4' then @gestprim else @gestiune end),			
			-->pretul cu amnuntul se ia din dreptul categoriei de pret
			--isnull(convert(varchar(20),(select top 1 pret_cu_amanuntul from preturi where cod_produs=p.cod and um=@CategPret 
			--	order by data_inferioara desc)),0) as pamanunt,
			rtrim(n.Denumire) as denumire, convert(varchar(20),p.Cant_aprobata) as cant_aprobata, convert(varchar(20),p.Pret_promotional) as cant_generata,
			RTRIM(p.Subunitate) as subunitate,RTRIM(p.tip) as tip, convert(varchar(10),p.data,101)as data, RTRIM(p.Contract) as contract, RTRIM(p.Tert) as tert,
			Numar_pozitie as numar_pozitie 	
		from pozcon p
			left outer join nomencl n on p.Cod=n.Cod 
		where p.Subunitate=@sub and p.tip='BK' 
			and p.contract=@contract and (p.tert='' or p.tert=@tert) and p.data=@data
			--and p.cant_aprobata-p.Pret_promotional>0.001-->mai exista cantitate aprobata care nu a fost deja transferata
	  FOR XML raw, type  
	  )  
	FOR XML path('DateGrid'), root('Mesaje')

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch