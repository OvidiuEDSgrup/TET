drop view yso_vIaSysspd 
go
create view yso_vIaSysspd as
select Denumire_cod=ISNULL(n.Denumire,'NU EXISTA articolul cu acest cod')
,s.Host_id,s.Host_name,s.Aplicatia,s.Data_stergerii,s.Stergator,s.Data_operarii,s.Ora_operarii,s.Subunitate,s.Tip,s.Numar
,s.Cod,s.Data,s.Gestiune,s.Cantitate,s.Pret_valuta,s.Pret_de_stoc,s.Adaos,s.Pret_vanzare,s.Pret_cu_amanuntul,s.TVA_deductibil
,s.Cota_TVA,s.Utilizator,s.Cod_intrare,s.Cont_de_stoc,s.Cont_corespondent,s.TVA_neexigibil,s.Pret_amanunt_predator
,s.Tip_miscare,s.Locatie,s.Data_expirarii,s.Numar_pozitie,s.Loc_de_munca,s.Comanda,s.Barcod,s.Cont_intermediar
,s.Cont_venituri,s.Discount,s.Tert,s.Factura,s.Gestiune_primitoare,s.Numar_DVI,s.Stare,s.Grupa,s.Cont_factura,s.Valuta
,s.Curs,s.Data_facturii,s.Data_scadentei,s.Procent_vama,s.Suprataxe_vama,s.Accize_cumparare,s.Accize_datorate,s.Contract
,s.Jurnal
 from sysspd s left join nomencl n on n.cod=s.cod 
--where s.Data_stergerii between '2012-08-01' and '2012-10-02'
go
drop proc yso_xIaSysspd 
go
create proc yso_xIaSysspd (@top int=65500,@datainf datetime='',@datasup datetime='',@listautilizexcep varchar(2048)='') as
select top (@top) * from yso_vIaSysspd v
where v.Data_stergerii between @datainf and @datasup
	and charindex(';' + rtrim(Stergator) + ';', ';'+@listautilizexcep+';') <= 0
	and v.Numar not like '[1-3]00[0-9][0-9]'
order by v.Data_stergerii 
go