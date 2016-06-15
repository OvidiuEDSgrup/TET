--***
/**	functie pt. centralizator certificate CM */
Create 
function [dbo].[CertificateCMFnuass] (@DataJ datetime, @DataS datetime, @alfabetic int) 
returns @CertificateCMFnuass table
	(Nrcrt int identity, Data datetime, Nume char(50), Cnp_asigurat char(13), CNP_copil char(13), 
	Serie_CCM char(5), Numar_CCM char(10), Serie_CCM_initial char(5), Numar_CCM_initial char(10),
	Cod_indemnizatie char(2), Ordonare char(50))
as
begin

	declare @utilizator varchar(20)
	Set @utilizator = dbo.fIaUtilizator('')

	insert into @CertificateCMFnuass (Data, Nume, Cnp_asigurat, CNP_copil, Serie_CCM, Numar_CCM, Serie_CCM_initial, Numar_CCM_initial, Cod_indemnizatie, Ordonare)
		select cm.Data, rtrim(a.numeAsig)+' '+rtrim(a.prenAsig), cm.cnpAsig, isnull(cm.D_8,''), cm.D_1, cm.D_2, isnull(cm.D_3,''), isnull(cm.D_4,''), cm.D_9, 
		(case when @alfabetic=1 then a.numeAsig else cm.cnpAsig end) as ordonare
	from D112asiguratD cm 
		left outer join D112asigurat a on a.Data=cm.Data and a.cnpAsig=cm.cnpAsig
	where cm.data between @DataJ and @DataS 
	order by cm.data, ordonare
	return
end

/*
	select * from CertificateCMFnuass ('02/01/2011', '02/28/2011', 0) 
*/
