interface Resource {
  id: string;
}

interface Item {
  id: string;
}

const series = []

const items = {
  item: [],
  file: [],
  subseries: [],
  otherlevel: [],
}

const dlevel = async (c: any): Promise<Item> => {
  if (c.did?.unitid) {
    const { level } = c
    const { container, unitdate, unitid, unittitle } = c.did
    const dates = []
    for await (const _unitdate of unitdate) {
      dates.push(_unitdate.value)
    }
    // console.log(unitid)
    // console.log(dates)
    // console.log(unittitle.value)
    // console.log(container)
    if (c?.did) { // recursion - do again.
      // console.log(c.did)
      // for await (const scopecontent of _c.scopecontent) {
        // console.log(scopecontent.head.value)
        // for await (const _scopecontent of scopecontent.children) {
          // console.log(_scopecontent.value.value)
        // }
      // }
    }
    if (c?.scopecontent) {
      for await (const scopecontent of c.scopecontent) {
        // console.log(scopecontent.head.value)
        for await (const _scopecontent of scopecontent.children) {
          // console.log(_scopecontent.value.value)
        }
      }
    }
    if (c?.odd) {
      for await (const odd of c.odd) {
        // console.log(odd.head.value)
        for await (const _odd of odd.children) {
          // console.log(_odd.value.value)
        }
      }
    }      
  }
  return { id: 'hola' }
}

const desc = async (c: any): Promise<void> => {
  if (c && 'c' in c) {
    for await (const _c of c.c) {
      await desc(_c.c)
    }
  } else {
    if (typeof c !== 'undefined') {
      if (Array.isArray(c)) {
        for (const _c of c) {
          if (_c && 'c' in _c) {
            for await (const __c of _c.c) {
              await desc(__c.c)
            }
          } else {
            series.push(c)
          }
        }
      } else {
        series.push(c)
      }
    }
  }
}

const filename = '/content/prod/rstar/content/fales/mss208/aux/mss_208.json'

const file = await Deno.readTextFile(filename)

const data = JSON.parse(file)

const { archdesc, eadheader, runinfo }  = data

const { sourcefile } = runinfo

const  { eadid, filedesc, profiledesc } = eadheader

// eadheader start

// EAD Url
const { url } = eadid

const { publicationstmt, titlestmt } = filedesc

const { author, sponsor, titleproper } = titlestmt

const { publisher } = publicationstmt

const { langusage } = profiledesc

const {
  level,
  accessrestrict,
  appraisal,
  arrangement,
  bioghist,
  controlaccess,
  custodhist,
  did,
  dsc,
  prefercite,
  processinfo,
  relatedmaterial,
  scopecontent,
  separatedmaterial,
  userestrict
} = archdesc

// https://github.com/nyudlts/findingaids-hugo-v4/blob/main/themes/findingaids-hugo-theme/layouts/_default/baseof.html

for await (const c of dsc.c) {
  desc(c)
}

for await (const serie of series) {
  if (Array.isArray(serie)) {
    for await (const s of serie) {
      const { level } = s
      items[level].push(s)
    }
  } else {
    const { level } = serie
    items[level].push(serie)
  }
}

await Deno.writeTextFile('./item.json', JSON.stringify({ data: items.item }, null, 2), { spaces: 2 })
await Deno.writeTextFile('./file.json', JSON.stringify({ data: items.file }, null, 2), { spaces: 2 })
await Deno.writeTextFile('./subseries.json', JSON.stringify({ data: items.subseries }, null, 2), { spaces: 2 })
await Deno.writeTextFile('./otherlevel.json', JSON.stringify({ data: items.otherlevel }, null, 2), { spaces: 2 })

// archdesc ends
