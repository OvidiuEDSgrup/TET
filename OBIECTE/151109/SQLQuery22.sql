with s as (
select top 1 * from sesiuniRIA s order by s.activitate
) delete s