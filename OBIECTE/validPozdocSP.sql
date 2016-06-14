IF  EXISTS (select * from sysobjects where name ='validPozdocSP')
	DROP PROCEDURE validPozdocSP
GO
create procedure validPozdocSP
as
begin try
		declare @eroare varchar(max)
	
	select * from #validPozdocSP
	
	if exists(select 1 
				from #validPozdocSP p
					inner join nomencl n on n.Cod=p.cod
				where isnull(p.comanda,'')<>''
					and isnull(c.Loc_de_munca,'')<>''
					and p.tip in ('CM','RS')
					and isnull(p.loc_de_munca,'')<>isnull(c.Loc_de_munca,'')					
			)
		raiserror('Locul de munca al comenzii nu se potriveste cu locul de munca de pe document!',11,1)

end try
begin catch
	DECLARE @mesaj varchar(max)
	set @mesaj=ERROR_MESSAGE()+ ' (validPozdocSP)'
	raiserror(@mesaj, 16,1)
end catch