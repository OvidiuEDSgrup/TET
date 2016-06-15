--***
create procedure wIaProdNeterminata (@sesiune varchar(50), @parXML xml)
as
declare @eroare varchar(500)
set @eroare=''
begin try
	declare @datajos datetime, @datasus datetime, @f_lm varchar(20), @f_comanda varchar(50),
			@tip_comanda varchar(100), @utilizator varchar(50), @lm varchar(20), @comanda varchar(20)
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator

	select	@datajos=@parxml.value('(row/@datajos)[1]','datetime')
		,@datasus=@parxml.value('(row/@datasus)[1]','datetime')
		,@f_lm=isnull(@parxml.value('(row/@f_lm)[1]','varchar(20)'),'')+'%'
		,@f_comanda=isnull(@parxml.value('(row/@f_comanda)[1]','varchar(50)'),'%')
		,@tip_comanda=@parxml.value('(row/@tip_comanda)[1]','varchar(50)')	
		,@lm=@parxml.value('(row/@lm)[1]','varchar(20)')
		,@comanda=@parxml.value('(row/@comanda)[1]','varchar(50)')		
			
	select top 100
		 convert(varchar(20),n.data,101) data, rtrim(n.loc_de_munca) lm, rtrim(n.comanda) comanda
		,convert(decimal(20,3),n.procent) procent, convert(decimal(20,3),n.cantitate) cantitate
		,convert(decimal(20,3),n.Valoare) valoare
		,rtrim(c.Descriere) as dencomanda, rtrim(c.tip_comanda) as tipcomanda, rtrim(lm.Denumire) as denlm
		,@datajos datajos, @datasus datasus
	from 
		nete n
		left join comenzi c on n.comanda=c.comanda
		left join lm on n.loc_de_munca=lm.Cod
	where n.data between @datajos and @datasus 
		and (n.loc_de_munca=@lm or isnull(@lm,'')='')
		and (n.comanda=@comanda or isnull(@comanda,'')='')
		and (isnull(@f_lm,'')='' or n.Loc_de_munca like @f_lm+'%' or lm.Denumire like '%'+@f_lm+'%')
		and (isnull(@f_comanda,'')='' or n.comanda like rtrim(@f_comanda)+'%' or c.descriere like '%'+@f_comanda+'%')
		and ((dbo.denTipComanda(c.tip_comanda) like '%'+@tip_comanda+'%' and len(@tip_comanda)>1) or c.Tip_comanda=@tip_comanda or isnull(@tip_comanda,'')='')
	order by n.loc_de_munca, n.comanda
	for xml raw
end try
begin catch
	set @eroare='wIaProdNeterminata:'+char(10)+error_message()
end catch

if len(@eroare)>0 raiserror(@eroare,16,1)

/*
select * from nete
*/
