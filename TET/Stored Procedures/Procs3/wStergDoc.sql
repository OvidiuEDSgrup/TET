--***
create procedure wStergDoc @sesiune varchar(50), @parXML xml 

as

Declare @cSub char(9), @mesajeroare varchar(100), @eroare xml 
exec luare_date_par 'GE', 'SUBPRO', 0,0,@cSub output 

begin try
	
	declare @doc table(subunitate varchar(50), tip char(2), numar varchar(20), data datetime, factura varchar(20), data_facturii datetime, numardvi varchar(50), tert varchar(50))

	declare @iDoc int 
	exec sp_xml_preparedocument @iDoc output, @parXML  
	   
	insert into @doc(subunitate, tip, numar, data, tert, factura, data_facturii, numardvi)
	select subunitate, tip, numar, data, tert, factura, data_facturii, numardvi
	from OPENXML(@iDoc, '/row')  
	 WITH  
	 (  
	  subunitate char(9) '@subunitate',   
      tip char(2) '@tip',   
	  numar char(20) '@numar', 
	  data datetime '@data',
	  tert varchar(20) '@tert',
	  factura varchar(20)'@factura',
	  data_facturii datetime '@datafacturii',
	  numardvi char(13) '@numardvi'
	 ) as dx  

	-- aici se va verifica sa nu aiba vreo incasare
	if exists( select 1 from pozplin p, @doc dx where p.subunitate=dx.subunitate and p.data=convert(datetime,dx.data,103) and p.Tert=dx.tert and p.factura=dx.factura and p.Plata_incasare='IB' ) 
		raiserror('Factura nu se poate sterge deoarece este incasata!', 16,1)

	-- aici se va verifica sa nu fie un antet de factura anulata (stare=?)
	if exists (select 1 from doc d, @doc dx where d.tip in ('AP','AS') and d.subunitate=dx.subunitate and d.tip=dx.tip and d.Numar=dx.numar and d.data=dx.data and stare='1') 
		raiserror('Factura este anulata!', 16, 1)

	-- are pozitii
	if exists (select 1 from pozdoc d, @doc dx where d.subunitate=dx.subunitate and (d.tip=dx.tip or ((d.Tip='RM' and dx.tip in ('RC','RF','RA')) OR (d.tip='AP' and dx.tip in ('AA','AB')))) and d.Numar=dx.numar and d.data=dx.data)
		raiserror('Documentul are pozitii!', 16, 1)

	-- receptie cu prestari
	if exists(select 1 from pozdoc d, @doc dx  
			where d.subunitate=dx.subunitate and d.Tip in('RP','RZ') and d.Numar=dx.numar and d.data=dx.data) 
		raiserror('Documentul are prestari!', 16, 1)

	-- fisiere atasate
	if exists(select 1 from FisiereDocument f, @doc dx  
			where f.Tip=dx.Tip and f.Numar=dx.numar and f.data=dx.data) 
		raiserror('Documentul are fisere atasate!', 16, 1)
	
--	sterg pozitia din tabela facturi
	delete facturi from facturi, @doc dx  
		where facturi.subunitate=dx.subunitate and dx.tip in ('AP','AS') and facturi.factura=dx.factura	and facturi.tert=dx.tert and facturi.data=dx.data_facturii 
			and abs(facturi.valoare)<0.01 and abs(achitat)<0.01

--	sterg pozitia din tabela DVI
	delete DVI from DVI, @doc dx  
		where dvi.subunitate=dx.subunitate and dx.tip='RM' and dvi.Numar_DVI=dx.numardvi
			and dvi.numar_receptie=dx.numar and dvi.data_receptiei=convert(datetime,dx.data,103) 

--	sterg pozitia cu datele privind CIF din pozdoc
	delete pozdoc from pozdoc pd, @doc dx  
		where pd.subunitate=dx.subunitate and dx.tip='RM' and pd.tip='RQ' and pd.numar=dx.numar and pd.data=convert(datetime,dx.data,103) 

--	sterg pozitia cu datele privind prestarile din pozdoc
	delete pozdoc from pozdoc pd, @doc dx  
		where pd.subunitate=dx.subunitate and dx.tip='RM' and pd.tip='RP' and pd.numar=dx.numar and pd.data=convert(datetime,dx.data,103) 

	delete doc from doc d, @doc dx  
		where d.subunitate=dx.subunitate and (d.tip=dx.tip or ((d.Tip='RM' and dx.tip in ('RC','RF','RA')) OR (d.tip='AP' and dx.tip in ('AA','AB')))) -->in cazul 'RC', in doc avem tip ='RM'
			and d.numar=dx.numar and d.data=convert(datetime,dx.data,103) 
	
	-- sterg pozitiile din JurnalDocumente
	delete JurnalDocumente from JurnalDocumente j, @doc dx  
	where dx.tip=j.tip and dx.numar=j.numar and j.data=dx.data 

end try
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH

begin try 
	exec sp_xml_removedocument @iDoc 
end try 
begin catch end catch
