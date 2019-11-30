<#include "/abstracted/common.ftl">
<#if !this.entityFeature.list>
    <@call this.skipCurrent()/>
</#if>
<#--表格是否可选择-->
<#assign tableSelect=this.entityFeature.deleteBatch/>
<#--表格是否可排序-->
<#assign tableSort=this.listSortFields?? && this.listSortFields?size &gt; 0/>
<#--表格是否需要操作列-->
<#assign tableOperate=this.entityFeature.show || this.entityFeature.update || this.entityFeature.delete/>
<template>
  <div class="app-container">
    <div class="filter-container">
<#--渲染查询输入框-->
<#if this.queryFields?? && this.queryFields?size &gt; 0>
    <#list this.queryFields as id,field>
        <#if !QueryType.isBetween(field.queryType)>
      <el-input v-model="listQuery.${field.jfieldName}" placeholder="${field.fieldDesc}"
                style="width: 200px;" class="filter-item"
                @keyup.enter.native="handleQuery"/>
        <#else>
        <#-- TODO 其他类型查询条件 -->
        </#if>
    </#list>
      <el-button class="filter-item" icon="el-icon-search" type="primary"
                 @click="handleQuery">
        搜索
      </el-button>
</#if>
<#if this.entityFeature.save>
      <el-button class="filter-item" style="margin-left: 10px;" type="primary"
                 icon="el-icon-edit" @click="handleCreate">
        新建
      </el-button>
</#if>
<#if this.entityFeature.deleteBatch>
      <el-button class="filter-item" style="margin-left: 10px;" type="danger"
                 icon="el-icon-delete" @click="handleDeleteBatch">
        删除
      </el-button>
    </div>
</#if>

    <el-table v-loading="listLoading" :data="list"
<#if tableSelect>
              @selection-change="selectionChange"
</#if>
<#if tableSort>
              @sort-change="sortChange"
</#if>
              border style="width: 100%;">
<#if tableSelect>
      <el-table-column type="selection" width="50" />
</#if>
<#list this.listFields as id,field>
      <el-table-column label="${field.fieldDesc}" prop="id"
    <#if field.listSort>
                       sortable="custom"
    </#if>
                                    <#-- TODO 列宽 -->
                       align="center" width="100">
        <template slot-scope="{row}">
          <span>{{ row.${field.jfieldName} }}</span>
        </template>
      </el-table-column>
</#list>
<#if tableOperate>
      <el-table-column label="操作" align="center" width="230"
                       class-name="small-padding fixed-width">
        <template slot-scope="{row}">
    <#if this.entityFeature.show>
          <el-button size="mini" @click="handleShow(row)">
            查看
          </el-button>
    </#if>
    <#if this.entityFeature.update>
          <el-button type="primary" size="mini" @click="handleUpdate(row)">
            编辑
          </el-button>
    </#if>
    <#if this.entityFeature.delete>
          <el-button type="danger" size="mini" @click="handleDeleteSingle(row)">
            删除
          </el-button>
    </#if>
        </template>
      </el-table-column>
</#if>
    </el-table>
<#if this.pageSign>
    <pagination v-show="total>0" :total="total" :page.sync="listQuery.page"
                :limit.sync="listQuery.limit" @pagination="doQueryList"/>
</#if>
<#if tableOperate>
    <el-dialog :title="formTitleMap[formStatus]" :visible.sync="formVisible">
      <el-form ref="dataForm" :rules="formRules" :model="form"
               label-position="left"
               label-width="100px" style="width: 400px; margin-left:50px;">
    <#list this.showFields as id,field>
        <el-form-item label="${field.fieldDesc}" prop="${field.jfieldName}">
          <span <#if field.update>v-if="formStatus === 'show'"</#if> class="form-item-show">{{form.${field.jfieldName}}}</span>
        <#if field.update>
          <el-input v-else v-model="form.${field.jfieldName}" />
        </#if>
        </el-form-item>
    </#list>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="formVisible = false">
          取消
        </el-button>
    <#if this.entityFeature.save || this.entityFeature.update>
        <el-button type="primary" <#if this.entityFeature.update>v-if="formStatus!=='show'"</#if>
                   @click="<#if this.entityFeature.save>formStatus==='create'?createData():</#if>updateData()">
          确认
        </el-button>
    </#if>
      </div>
    </el-dialog>
</#if>
  </div>
</template>

<script>
import ${this.className}Api from '@/api/${this.className}'
<#if this.pageSign>
import Pagination from '@/components/Pagination'
</#if>

export default {
  name: '${this.classNameUpper}Table',
<#if this.pageSign>
  components: { Pagination },
</#if>
  data() {
    return {
      list: [],
      total: 0,
      listLoading: true,
      listQuery: {
<#if this.pageSign>
        page: 1,
        limit: 10,
</#if>
<#list this.queryFields as id,field>
        name: undefined,
</#list>
        idSortNo: null
      },
      selectItems: [],
      form: {
        id: undefined,
        name: ''
      },
      formVisible: false,
      formStatus: '',
      formTitleMap: {
        show: '查看${this.title}',
        update: '编辑${this.title}',
        create: '新建${this.title}'
      },
      formRules: {
        name: [{ required: true, message: '请输入${field.fieldDesc}', trigger: 'blur' }]
      }
    }
  },
  created() {
    this.doQueryList({ page: 1 })
  },
  methods: {
    /**
     * 选择框变化
     */
    selectionChange(val) {
      this.selectItems = val
    },
    /**
     * 触发后端排序
     */
    sortChange({ prop, order }) {
      const sortKeyMap = {
        'id': 'idSortNo'
      }
      for (var k in sortKeyMap) {
        const sortKey = sortKeyMap[k]
        if (k !== prop) {
          this.listQuery[sortKey] = null
        } else {
          if (order === 'ascending') {
            this.listQuery[sortKey] = 1
          } else {
            this.listQuery[sortKey] = -1
          }
        }
      }
      this.doQueryList({})
    },
    /**
     * 触发搜索操作
     */
    handleQuery() {
      this.doQueryList({ page: 1 })
    },
    /**
     * 执行列表查询
     */
    doQueryList({ page, limit }) {
      if (page) {
        this.listQuery.page = page
      }
      if (limit) {
        this.listQuery.limit = limit
      }
      this.listLoading = true
      return roleApi.fetchList(this.listQuery)
        .then(data => {
          this.list = data.list
          this.total = data.total
        })
        .finally(() => {
          this.listLoading = false
        })
    },
    /**
     * 删除单条记录
     */
    handleDeleteSingle(row) {
      return this.$common.confirm('是否确认删除')
        .then(() => roleApi.deleteById(row.id))
        .then(() => {
          this.$common.showMsg('success', '删除成功')
          return this.doQueryList({ page: 1 })
        })
    },
    /**
     * 批量删除记录
     */
    handleDeleteBatch() {
      if (this.selectItems.length <= 0) {
        this.$common.showMsg('warning', '请选择${this.title}')
        return
      }
      return this.$common.confirm('是否确认删除')
        .then(() => roleApi.deleteBatch(this.selectItems.map(row => row.id)))
        .then(() => {
          this.$common.showMsg('success', '删除成功')
          return this.doQueryList({ page: 1 })
        })
    },
    /**
     * 重置编辑表单
     */
    resetForm(data) {
      if (data) {
        this.form = data
      } else {
        this.form = {
          id: undefined,
          name: ''
        }
      }
    },
    /**
     * 打开新建表单
     */
    handleCreate() {
      this.resetForm()
      this.formStatus = 'create'
      this.formVisible = true
    },
    /**
     * 执行新建操作
     */
    createData() {
      return this.$refs['dataForm'].validate()
        .then(() => roleApi.create(this.form))
        .then(() => {
          this.formVisible = false
          this.$common.showMsg('success', '创建成功')
          return this.doQueryList({ page: 1 })
        })
    },
    /**
     * 打开查看表单
     */
    handleShow(row) {
      roleApi.fetchById(row.id)
        .then(data => {
          this.resetForm(data)
          this.formStatus = 'show'
          this.formVisible = true
        })
    },
    /**
     * 打开编辑表单
     */
    handleUpdate(row) {
      roleApi.fetchById(row.id)
        .then(data => {
          this.resetForm(data)
          this.formStatus = 'update'
          this.formVisible = true
        })
    },
    /**
     * 执行修改操作
     */
    updateData() {
      return this.$refs['dataForm'].validate()
        .then(() => {
          roleApi.update(this.form)
        })
        .then(() => {
          this.formVisible = false
          this.$common.showMsg('success', '修改成功')
          return this.doQueryList({})
        })
    }
  }
}
</script>