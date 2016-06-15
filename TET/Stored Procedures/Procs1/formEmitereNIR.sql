--***
create procedure formEmitereNIR @sesiune varchar(50), @parXML xml, @numeTabelTemp varchar(100) output
as
begin try

	declare
		@utilizator varchar(20), @mesajEroare varchar(500), @unitate varchar(100),
		@ro varchar(100), @nrrc varchar(100), @localitate varchar(100),
		@cTextSelect nvarchar(max), @tip varchar(2), @numar varchar(20), @data datetime

	set @unitate = (select val_alfanumerica as nume from par where Tip_parametru = 'GE' and Parametru = 'NUME')
	set @ro = (select val_alfanumerica from par where Tip_parametru = 'GE' and Parametru = 'CODFISC')
	set @nrrc = (select val_alfanumerica from par where Tip_parametru = 'GE' and Parametru = 'ORDREG')
	set @localitate = (select val_alfanumerica from par where Tip_parametru = 'GE' and Parametru = 'SEDIU')

	select
		@tip = @parXML.value('(/*/@tip)[1]', 'varchar(2)'),
		@numar = @parXML.value('(/*/@numar)[1]', 'varchar(20)'),
		@data = @parXML.value('(/*/@data)[1]', 'datetime')

	select
		rtrim(@unitate) as UNITATE,
		rtrim(@ro) as RO,
		rtrim(@nrrc) as NRRC,
		rtrim(@localitate) as LOCALITATE,
		max(convert(char(12),p.Data, 104)) as DATA,
		rtrim(max(p.numar)) as DOC,
		rtrim(max(g.Denumire_gestiune)) as GEST,
		rtrim(max(t.Denumire)) as FURN,
		rtrim(max(p.factura)) as FACT,
		row_number() over (order by p.Numar_pozitie) as NR,
		rtrim(p.cod) as COD,
		rtrim(max(n.Denumire)) as DENUMIRE,
		rtrim(n.um) as UM,
		convert(decimal(15,2), p.Pret_de_stoc) as PRET,
		convert(decimal(15,2), p.Cantitate) as CANT,
		convert(decimal(15,2), p.Pret_de_stoc * p.Cantitate) as VAL,
		convert(decimal(15,2), p.Cantitate * p.Pret_cu_amanuntul * p.Cota_TVA/(100 + p.Cota_TVA)) as TVA,
		(select convert(decimal(15,2), sum(poz.Pret_de_stoc * poz.Cantitate)) from pozdoc poz where poz.Subunitate = max(p.Subunitate) and poz.Tip = max(p.Tip) and poz.Data = max(p.Data) and poz.Numar = max(p.Numar)) as TVAL,
		(select convert(decimal(15,2), sum(poz.Cantitate * poz.Pret_cu_amanuntul * poz.Cota_TVA/(100 + poz.Cota_TVA))) from pozdoc poz where poz.Subunitate = max(p.Subunitate) and poz.Tip = max(p.Tip) and poz.Data = max(p.Data) and poz.Numar = max(p.Numar)) as TTVA,
		(select convert(decimal(15,2), sum(poz.Pret_de_stoc * poz.Cantitate) + isnull(max(d.Valoare_TVA), sum(poz.TVA_deductibil))) from pozdoc poz left join DVI d on d.Subunitate = poz.Subunitate and d.Numar_receptie = poz.Numar and d.Data_receptiei = poz.Data and d.Numar_DVI = poz.Numar_DVI
			where poz.subunitate = max(p.Subunitate) and poz.Tip = max(p.Tip) and poz.numar = max(p.Numar) and poz.Data = max(p.Data)) as TOTAL,
		convert(decimal(15,2), p.Cantitate * (round(p.Pret_cu_amanuntul, 2) - round(p.Pret_cu_amanuntul * p.Cota_TVA/(100 + p.Cota_TVA) + p.Pret_de_stoc, 2))) as ADAOS,
		max(convert(char(12), p.Data_facturii, 104)) as DATAF,
		(select convert(decimal(15,2), sum(poz.Cantitate * round(poz.Pret_cu_amanuntul, 2) - round(poz.Pret_cu_amanuntul * poz.Cota_TVA/(100 + poz.Cota_TVA) + poz.Pret_de_stoc, 2))) from pozdoc poz
			where poz.Subunitate = max(p.Subunitate) and poz.Tip = max(p.Tip) and poz.Data = max(p.Data) and poz.Numar = max(p.Numar)) as ADAOSTOTAL,
		rtrim(max(t.Localitate)) as LOCALF,
		(select convert(decimal(15,2), sum(poz.Cantitate)) from pozdoc poz where poz.Subunitate = max(p.Subunitate) and poz.Tip = max(p.Tip) and poz.Data = max(p.Data) and poz.numar = max(p.Numar)) as CANTT,
		convert(decimal(15,2), round(p.Pret_cu_amanuntul, 2) - round(p.Pret_cu_amanuntul * p.Cota_TVA/(100 + p.Cota_TVA) + p.Pret_de_stoc, 2)) as ADAOSU,
		convert(decimal(15,2), round(p.Pret_cu_amanuntul, 2) - round(p.Pret_cu_amanuntul * p.Cota_TVA/(100 + p.Cota_TVA), 2)) as PRETUA,
		convert(decimal(15,2), round(max(p.Pret_cu_amanuntul), 2)) as PRETVU,
		convert(decimal(15,2), round(max(p.Cantitate * p.Pret_cu_amanuntul), 2)) as PRETVUT,
		convert(decimal(15,2), round(p.Pret_cu_amanuntul * p.Cota_TVA/(100 + p.Cota_TVA), 2)) as TVAU,
		rtrim(convert(char(17),convert(money,(round(p.pret_cu_amanuntul,2)-round(p.pret_cu_amanuntul*p.cota_tva/(100+p.cota_tva)+p.pret_de_stoc,2))/p.pret_de_stoc*100),1)) as ADAOSPR,
		convert(char(17),convert(money,round((select sum(poz.cantitate*(round(poz.pret_cu_amanuntul,2)-round(poz.pret_cu_amanuntul*poz.cota_tva/(100+poz.cota_tva)+poz.pret_de_stoc,2)))/sum(poz.cantitate*poz.pret_de_stoc)*100 from pozdoc poz 
			where poz.subunitate=max(p.subunitate) and poz.tip=max(p.tip) and poz.data=max(p.data) and poz.numar=max(p.numar)),2)),1) as ADAOSPRT,
		(select convert(decimal(15,2), sum(round(poz.Cantitate * poz.Pret_cu_amanuntul, 2))) from pozdoc poz where poz.Subunitate = max(p.Subunitate) and poz.Tip = max(p.Tip) and poz.Data = max(p.Data) and poz.Numar = max(p.Numar)) as VALVT
	into #selectMare
	from pozdoc p, gestiuni g, terti t, nomencl n
	where p.Tip = @tip
		and p.Data = @data
		and p.Numar = @numar
		and p.Cod = n.Cod 
		and t.Tert = p.Tert 
		and g.Cod_gestiune = p.Gestiune
	group by p.Cod, p.Adaos, p.pret_vanzare, p.Factura, n.um, p.Cantitate, p.Pret_de_stoc, p.TVA_deductibil, p.Pret_cu_amanuntul, p.Cota_TVA, p.Numar_pozitie
	order by p.Numar_pozitie

	set @cTextSelect = '
	select *
	into ' + @numeTabelTemp + '
	from #selectMare
	'

	exec sp_executesql @statement = @cTextSelect

end try
begin catch
	set @mesajEroare = ERROR_MESSAGE() + ' (formEmitereNIR)'
	raiserror(@mesajEroare, 16, 1)
end catch
