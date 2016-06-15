create proc yso_xIaSysspd (@top int=65500,@datainf datetime='',@datasup datetime='',@listautilizexcep varchar(2048)='') as
select top (@top) * from yso_vIaSysspd v
where v.Data_stergerii between @datainf and @datasup
	and charindex(';' + rtrim(Stergator) + ';', ';'+@listautilizexcep+';') <= 0
	and v.Numar not like '[1-3]00[0-9][0-9]'
order by v.Data_stergerii 
