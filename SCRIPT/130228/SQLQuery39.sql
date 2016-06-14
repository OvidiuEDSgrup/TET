select top 1000 * from sysspd s 
where s.Aplicatia='Microsoft SQL Server Managemen' and s.Stergator='asis'
order by s.Data_stergerii desc