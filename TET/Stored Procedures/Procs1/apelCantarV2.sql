--***

CREATE procedure [dbo].[apelCantarV2] @sesiune varchar(50), @parxml xml as --Are lungime fixa de 66x2 = 112 caractere. La final pun spatii
DECLARE @PREFIXBC VARCHAR(2), @string varchar(max)

declare @gestutiliz varchar(20),@categoriepret int,@utilizator varchar(100)	
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
print @utilizator
	set @gestutiliz=isnull((select max(valoare) from proprietati where tip='UTILIZATOR' and 
		cod_proprietate='GESTPV' and cod=@utilizator),'')
	set @categoriePret=isnull((select valoare from proprietati where tip='GESTIUNE' and cod_proprietate='CATEGPRET' and cod=@gestutiliz and Valoare<>''),'201')


SET @PREFIXBC='29'
set @string=''


SELECT @string = @string + 
	UPPER(
	isnull(REPLICATE('0',8-LEN(LTRIM(RTRIM(cb.cb)))),'')+LTRIM(RTRIM(cb.cb)) -- as cod
	+'003B' --AS LUNGIME,
	+'70000D2000' -- PLU STATUS
	+REPLACE(STR(ROUND(P.Pret_cu_amanuntul*100,0),8),' ','0') -- PRET
	+'11' -- FORMAT ETICHETA
	+'05'+@PREFIXBC
	+isnull(REPLICATE('0',5-LEN(LTRIM(RTRIM(cb.cb)))),'')+isnull(LTRIM(RTRIM(cb.cb)),'')+'0000000'
	+'070E'+	--DIMENSIUNE M3 PENTRU PRIMA LINIE + 15 caractere
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,1,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,2,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,3,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,4,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,5,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,6,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,7,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,8,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,9,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,10,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,11,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,12,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,13,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,14,1))),2),'20')
	+'0D' --Gata prima linie
	+'070E' --Dimesiune M3 pentru a doua linie + 15 caractere
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,15,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,16,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,17,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,18,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,19,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,20,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,21,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,22,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,21,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,24,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,25,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,26,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,27,1))),2),'20')
	+isnull(right(master.dbo.fn_varbintohexstr(ascii(substring(n.denumire,28,1))),2),'20')
	+'0C'
	+'00')

from nomencl n
   inner join 
	(select max(cod_de_bare) as cb,cod_produs as cod
		from codbare
		where LEN(Cod_de_bare)<=5 /* cantarul DIGI stie doar coduri cu max 5 caractere */
			and cod_produs in (select n.cod
			from nomencl n where n.um='KG')
		group by cod_produs
	) cb on cb.cod=n.cod
   inner join  
   		(select RANK() over (partition by p.cod_produs order by p.tip_pret desc,p.data_inferioara desc) as nrank, p.Cod_produs,p.Pret_cu_amanuntul
			from preturi p
			inner join nomencl n on p.Cod_produs=n.Cod
			where p.um=@categoriePret
			and ((p.tip_pret=1 and GETDATE()>=p.Data_inferioara)
				or (p.tip_pret=2 and GETDATE() between p.Data_inferioara and p.data_superioara))) p 
  
   on n.Cod=p.Cod_produs and p.nrank=1
   where UM='kg' 

/*
if not exists(select 1 from sysobjects where name='apelcantar')
begin
	create table apelcantar(ut varchar(20),sir varchar(max))
	create unique index pCantar on apelcantar(ut)
end
else
	delete from apelcantar where ut=@	

insert into apelcantar(ut,sir) values (@utilizator,@string)
*/
select @string as col1
