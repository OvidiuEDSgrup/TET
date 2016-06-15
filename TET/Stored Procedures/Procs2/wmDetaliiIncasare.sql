
CREATE procedure wmDetaliiIncasare @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmDetaliiIncasareSP' and type='P')
begin
	exec wmDetaliiIncasareSP @sesiune=@sesiune, @parXML=@parXML
	return 0
end

begin try
	declare
		@suma float, @rest float, @sume xml, @actiune xml, @facturi xml, @tert varchar(100), @valoareFactura float, @factura varchar(20),@dData datetime,
		@suma_initiala float, @factura_select varchar(20), @utilizator varchar(100), @tabel xml, @suma_factura float, @populare bit,
		@numar varchar(20), @serie varchar(20), @punct_liv varchar(20)

	set @suma= ISNULL(@parXML.value('(/*/@suma)[1]','float'),0)
	set @rest= ISNULL(@parXML.value('(/*/@rest)[1]','float'),0)
	set @tert= @parXML.value('(/*/@tert)[1]','varchar(20)')
	set @punct_liv= @parXML.value('(/*/@pctliv)[1]','varchar(20)')
	set @serie= @parXML.value('(/*/@serie)[1]','varchar(20)')
	set @numar= @parXML.value('(/*/@numar)[1]','varchar(20)')
	set @factura_select= @parXML.value('(/*/@factura)[1]','varchar(20)')
	set @suma_factura= @parXML.value('(/*/@sold_factura)[1]','float')
	set @populare= ISNULL(@parXML.value('(/*/@populare)[1]','bit'),0)
	/** Variabila tabel va retine (si va pasa de la un view la altul) "tabelul" de facturi selectate */
	set @tabel=CONVERT(xml, @parXML.value('(/*/@tabel)[1]','varchar(max)'))
		
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	IF OBJECT_ID ('tempdb..#listaFacturi') IS NULL
		create table #listaFacturi(id int identity primary key, factura varchar(50), suma float)
	
	/** Variabile suma este folosite si in cursorul care "sparge" sumele pe facturi */
	set @suma_initiala=@suma

	/** Daca se alege o factura, fie o pun in tabelul de "selectate" cu suma corespunzatoare, fie o sterg de acolo**/
	if @factura_select is not null
	begin	
		insert into #listaFacturi (factura, suma)
		select
			D.c.value('(@factura)[1]','varchar(20)'),D.c.value('(@suma)[1]','float')
		FROM @tabel.nodes('/row') D(c)
	
		IF exists(select 1 from #listaFacturi where factura=@factura_select)
			delete from #listaFacturi where factura=@factura_select 
		else
			insert into #listaFacturi (factura, suma)
			select @factura_select, dbo.valoare_minima((case when @suma=0 then 9999999 else (select @suma_initiala-ISNULL(SUM(suma),0) from #listaFacturi) end), @suma_factura,0)
			--where dbo.valoare_minima((case when @suma=0 then 9999999 else (select @suma_initiala-ISNULL(SUM(suma),0) from #listaFacturi) end), @suma_factura,0)>0.0		

		set @tabel=(select factura, suma from #listaFacturi for xml raw)
		select ISNULL(convert(varchar(max),@tabel),'') tabel for xml raw('atribute'),root('Mesaje')
		return
	end
	
	if @tabel is not null
	begin
		
		insert into #listaFacturi (factura, suma)
		select
			D.c.value('(@factura)[1]','varchar(20)'),D.c.value('(@suma)[1]','float')
		FROM @tabel.nodes('/row') D(c)

		set @tabel=(select factura, suma from #listaFacturi for xml raw)
		select convert(varchar(max),@tabel) tabel for xml raw('atribute'),root('Mesaje')
	end

		
	if @populare=1
	/** Daca se acceseaza meniul de introducere suma, populez tabelul de facturi selectate in limita sumei introduse */
	begin
		truncate table #listaFacturi
		declare @listaFacturi cursor 		

		set @listaFacturi = cursor local fast_forward for
		select rtrim(f.Factura),  f.Valoare+f.TVA_11+f.TVA_22-f.Achitat,f.data
		from facturi f
		left join doc d on d.subunitate=f.subunitate and d.cod_tert=f.tert and d.factura=f.factura and d.data_facturii=f.data and d.tip ='AP'
			where f.tip=0x46 and f.tert=@tert 
				and (d.gestiune_primitoare=@punct_liv or isnull(@punct_liv,'')='' or isnull(d.gestiune_primitoare,'')='')
				and abs(f.sold)>=0.01
		order by f.Data asc, f.factura
			
		open @listaFacturi
		fetch next from @listaFacturi into @factura, @valoareFactura,@dData
		while @@FETCH_STATUS=0 and @suma>0
		begin 
			if @valoareFactura>@suma
				set @valoareFactura=@suma
			set @suma = @suma - @valoareFactura
			
			insert #listaFacturi(factura, suma)
			select rtrim(@factura), @valoareFactura
				
			fetch next from @listaFacturi into @factura, @valoareFactura,@dData
		end
		
		set @tabel=(select factura, suma from #listaFacturi for xml raw)
		select convert(varchar(max),@tabel) tabel,0 as populare for xml raw('atribute'),root('Mesaje')
	end

	
	/** Este afisat ca si detaliu al primei linii: fie suma ramasa de distribuit, fie suma de incasat daca se aleg facturi fara sa introduca suma */
	select @rest=ISNULL(@suma_initiala-ISNULL(sum(suma),0),0) from #listaFacturi 
	/** Linia care afiseaza si permite introducerea/schimbarea sumei */
	set @sume= 
	(
		select 
			'Suma ' + convert(varchar(100),convert(decimal(15,2),@suma_initiala)) 'denumire','suma' as cod,
			(Case WHEN @suma_initiala>0 then 'Rest ' else 'De incasat ' END) +
			convert(varchar(100),convert(decimal(15,2),isnull(@rest,0)*(CASE when @suma_initiala>0 then 1 else -1 end))) info,dbo.f_wmIaForm('CS') as form,
			'wmAlegSumaIncasare' procdetalii, 'assets/Imagini/Meniu/sold.png' as poza, '0x0000FF' as culoare,'D' as tipdetalii
		for XML RAW,type
	)

	/** Linia cu facturile */
	set @facturi= 
	(
		select 
			'Factura '+ RTRIM(f.Factura) +' - Data '+CONVERT(varchar(10), f.Data,103) as denumire,'factura' as cod,
			'Scad. ' +CONVERT(varchar(10), f.Data_scadentei,103) +' Sold ' +CONVERT(varchar(20), CONVERT(decimal(15,2),f.sold))+' - Suma: '+ISNULL(convert(varchar(10),convert(decimal(15,2),lf.suma)),0) as info,
			(CASE when lf.factura IS not null then '0x00FF00' end) as culoare, 'wmDetaliiIncasare' procdetalii, 'C' as tipdetalii,
			rtrim(f.factura) factura, '1' as _toateAtr, f.Sold sold_factura
		from facturi  f
		left join doc d on d.subunitate=f.subunitate and d.cod_tert=f.tert and d.factura=f.factura and d.data_facturii=f.data and d.tip ='AP'		
		LEFT JOIN #listaFacturi lf on lf.factura=f.factura
		where f.tip=0x46 and f.tert=@tert and abs(f.sold)>=0.01  
				and (d.gestiune_primitoare=@punct_liv or isnull(@punct_liv,'')='' or isnull(d.gestiune_primitoare,'')='')
				and abs(f.sold)>=0.01
		order BY f.Data asc, f.factura
		for xml raw, type
	)
	
	/** Linia de meniu cu actiunea de incasare ... */
	set @actiune=
	(
		select
			'incasare' as cod,'assets/Imagini/Meniu/incasari.png' as poza,'Incasare' as denumire,
			'wmProceseazaIncasare' as procdetalii, '0x0000FF' as culoare,
			dbo.f_wmIaForm('CH') as form,'D' as tipdetalii
		for xml RAW, type
	)

	select 
		'Detalii incasare' as titlu, 0 as areSearch,'refresh' actiune		
	for xml raw,Root('Mesaje')   
	
	select 
		@sume, @actiune, @facturi
	for xml PATH('Date')

end try
begin catch
	declare @eroare varchar(500)
	set @eroare=ERROR_MESSAGE()+'(wmDetaliiIncasare)'
	raiserror(@eroare,11,1)
end catch
