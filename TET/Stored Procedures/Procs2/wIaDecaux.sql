create procedure wIaDecaux @sesiune varchar(50), @parXML xml
as
declare @utilizator varchar(20), @Sub char(9),@iDoc int
	
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output
exec sp_xml_preparedocument @iDoc output, @parXML

select top 100 
	rtrim(d.subunitate) as subunitate,'DX' as tip,convert(char(10),dbo.eom(d.data),101) as data_lunii, RTRIM(d.L_m_furnizor) as l_m_furnizor,
	max(lmf.denumire) as denl_m_furnizor,RTRIM(d.Comanda_furnizor) as comanda_furnizor,max(cf.descriere) as dencomanda_furnizor,
	convert(decimal(15,2),SUM(d.Cantitate)) as totalCantitate,COUNT(1) as numarpozitii,
	convert(decimal(20, 3), sum(d.cantitate*isnull(pr.pret_unitar,0))) as valoare_calculata,
	max(convert(decimal(20, 3), isnull(pr.pret_unitar,0))) as pret_unitar_calculat
from decaux d
	cross join OPENXML(@iDoc, '/row')
	WITH
		(
			data_jos datetime '@datajos'
			,data_sus datetime '@datasus'
			,data datetime '@data'
			,denl_m_furnizor varchar(30) '@f_denl_m_furnizor'
			,dencomanda_furnizor varchar(80) '@f_dencomanda_furnizor'
			,comanda_furnizor varchar(80) '@comanda_furnizor'
			,l_m_furnizor varchar(30) '@l_m_furnizor'
			,f_lm_ben varchar(30) '@f_lm_ben'
			,f_comanda_ben varchar(80) '@f_comanda_ben'
		) as fx
	left outer join lm lmf on lmf.Cod=d.L_m_furnizor 
	left outer join lm lmb on lmb.Cod=d.Loc_de_munca_beneficiar 
	left outer join comenzi cf on cf.Comanda=d.Comanda_furnizor and cf.subunitate=@Sub
	left outer join comenzi cb on cb.comanda=d.comanda_beneficiar and cb.subunitate=@Sub
	left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=d.L_m_furnizor 
	outer apply(select top 1 pret_unitar from pretun pr where pr.comanda=d.Comanda_furnizor and dbo.eom(pr.data_lunii)=dbo.eom(d.data))pr
where d.subunitate=@Sub 
	and (dbo.f_areLMFiltru(@utilizator)=0 or lu.cod is not null)
	and (fx.data is null or d.data=fx.data)
	and d.data between isnull(fx.data_jos, '01/01/1901') and (case when isnull(fx.data_sus, '01/01/1901')<='01/01/1901' then '12/31/2999' else fx.data_sus end)
	and (lmf.denumire like '%'+isnull(fx.denl_m_furnizor, '')+'%' or d.L_m_furnizor like isnull(fx.denl_m_furnizor, '')+'%')
	and (cf.descriere like '%'+isnull(fx.dencomanda_furnizor, '')+'%' or d.Comanda_furnizor like isnull(fx.dencomanda_furnizor, '') + '%')
	/** Pentru identificarea antetului la scriere pozitii si refresh taburi*/
	and (isnull(fx.l_m_furnizor,'')='' OR d.L_m_furnizor=fx.l_m_furnizor)
	and (isnull(fx.comanda_furnizor,'')='' OR d.Comanda_furnizor=fx.comanda_furnizor)
	and (isnull(fx.f_lm_ben,'')='' OR d.Loc_de_munca_beneficiar like fx.f_lm_ben+'%' or lmb.denumire like '%'+fx.f_lm_ben+'%')
	and (isnull(fx.f_comanda_ben,'')='' OR d.Comanda_beneficiar like fx.f_comanda_ben+'%' or cb.descriere like '%'+fx.f_comanda_ben+'%')
group by d.Subunitate, dbo.eom(d.data), d.L_m_furnizor, d.Comanda_furnizor  
order by dbo.eom(d.data), d.L_m_furnizor, d.Comanda_furnizor   
for xml raw, ROOT('Date')

exec sp_xml_removedocument @iDoc 
/*
select * from decaux
*/

